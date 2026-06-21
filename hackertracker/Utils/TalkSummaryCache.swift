//
//  TalkSummaryCache.swift
//  hackertracker
//
//  On-device summarization of conference talk descriptions via the
//  Apple Intelligence Foundation Models framework.
//
//  The cache is the only thing that touches `FoundationModels` directly.
//  Call sites just ask for a summary by Content (`summary(for:)`) and
//  optionally pre-warm the cache (`warm(_:)`); availability gating,
//  concurrency limits, deduplication, and persistence are all internal.
//
//  Persistence: summaries land in UserDefaults as JSON keyed by content
//  id, with a SHA256 of the description so an edit on the server side
//  cleanly invalidates the cached summary. Capped at MAX_ENTRIES; oldest
//  by `createdAt` get pruned when we go over.
//

import Foundation
import CryptoKit
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Common shape shared by anything we know how to summarize. Lets
/// the cache accept any of: `Content` (All Content / Talks tab),
/// `Event` (Schedule tab), or `Speaker` (Speakers tab) without
/// duplicating method bodies.
protocol SummarizableTalk {
    var id: Int { get }
    var description: String { get }
    /// Stable key used by the persistence layer. Default impl returns
    /// the integer id as-is for talks; types that share id space with
    /// talks (e.g. `Speaker` may collide with `Content`/`Event` ids)
    /// override to namespace.
    var summaryCacheKey: String { get }
    /// Selects the prompt template. The talk-bio prompt isn't the same
    /// thing as the speaker-bio prompt — we want both targeted.
    var summaryKind: SummaryKind { get }
}

extension SummarizableTalk {
    var summaryCacheKey: String { String(id) }
    var summaryKind: SummaryKind { .talk }
}

enum SummaryKind {
    case talk     // Content + Event (conference talks)
    case speaker  // Bio of a person presenting
}

extension Content: SummarizableTalk {}
extension Event: SummarizableTalk {}
extension Speaker: SummarizableTalk {
    var summaryCacheKey: String { "speaker:\(id)" }
    var summaryKind: SummaryKind { .speaker }
}

@Observable
@MainActor
final class TalkSummaryCache {
    static let shared = TalkSummaryCache()

    /// Cap on concurrent in-flight summarization tasks. Apple's on-device
    /// LLM can serve several requests at once, but going too wide burns
    /// the user's battery and pushes interactive UI work off the main
    /// queue. Four is a balance that keeps scroll-induced pre-warms from
    /// piling up.
    private let maxConcurrent = 4

    /// Cap on stored entries. UserDefaults handles up to a few MB but we
    /// don't need to hoard summaries across hundreds of past conferences.
    /// Eviction is by oldest `createdAt`.
    private let maxEntries = 1000

    private static let defaultsKey = "aiSummaryCache.v1"

    /// Persisted entry. `descriptionHash` lets us notice when a talk's
    /// description has changed server-side and re-summarize instead of
    /// returning stale text.
    struct Entry: Codable {
        let descriptionHash: String
        let summary: String
        let createdAt: Date
    }

    private var memory: [String: Entry] = [:]
    @ObservationIgnored private var inflight: [String: Task<Void, Never>] = [:]
    /// FIFO queue of items waiting for a slot. We store key +
    /// description + kind rather than the SummarizableTalk itself so
    /// the queue isn't tied to either model type's lifecycle.
    @ObservationIgnored private var pending: [(key: String, description: String, kind: SummaryKind)] = []

    private init() {
        load()
    }

    // MARK: - Public API

    /// Returns the cached summary for `content` if we have one whose
    /// description hash matches the current description. Returns nil
    /// when there's no summary yet OR when the description has
    /// changed since we last summarized (the stale entry is dropped
    /// to force a re-warm).
    func summary(for item: any SummarizableTalk) -> String? {
        let key = item.summaryCacheKey
        guard let entry = memory[key] else { return nil }
        let currentHash = Self.stableHash(item.description)
        if entry.descriptionHash == currentHash {
            return entry.summary
        }
        // Description changed -> stale. Drop and let the next warm refill.
        memory.removeValue(forKey: key)
        persist()
        return nil
    }

    /// Minimum description length that warrants summarization.
    /// Below this, a one-sentence summary won't be shorter than
    /// (or substantively different from) the source — and burning
    /// the user's battery on a marginal gain isn't worth it.
    private let minDescriptionChars = 100

    /// Schedule a summary generation for `content`, deduplicated.
    /// No-op when:
    ///   - the device can't run FoundationModels right now,
    ///   - the description is missing or under `minDescriptionChars`,
    ///   - we already have an up-to-date summary, or
    ///   - there's already an inflight task for this id.
    func warm(_ item: any SummarizableTalk) {
        guard AISummaryAvailability.isSupported else { return }
        let trimmed = item.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minDescriptionChars else { return }
        guard summary(for: item) == nil else { return }
        let key = item.summaryCacheKey
        guard inflight[key] == nil else { return }

        if inflight.count >= maxConcurrent {
            if !pending.contains(where: { $0.key == key }) {
                pending.append((key, item.description, item.summaryKind))
            }
            return
        }
        spawn(key: key, description: item.description, kind: item.summaryKind)
    }

    // MARK: - Generation

    private func spawn(key: String, description: String, kind: SummaryKind) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            spawnReal(key: key, description: description, kind: kind)
            return
        }
        #endif
        // Older OS / no framework: silently do nothing.
        // `summary(for:)` will keep returning nil and call sites will
        // fall back to the existing description preview.
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func spawnReal(key: String, description: String, kind: SummaryKind) {
        let prompt = Self.prompt(for: description, kind: kind)

        let task = Task { @MainActor [weak self] in
            defer {
                self?.inflight.removeValue(forKey: key)
                self?.pump()
            }
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                let raw = response.content
                let summary = Self.cleanup(raw)
                guard !summary.isEmpty else { return }

                let entry = Entry(
                    descriptionHash: Self.stableHash(description),
                    summary: summary,
                    createdAt: Date()
                )
                self?.memory[key] = entry
                self?.prune()
                self?.persist()
                Log.app.debug("AI summary OK for \(key, privacy: .public): \(summary, privacy: .public)")
            } catch {
                Log.app.debug("AI summary failed for \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        inflight[key] = task
    }
    #endif

    /// Promote queued items into the inflight set, in arrival order,
    /// until we hit `maxConcurrent`.
    private func pump() {
        while inflight.count < maxConcurrent, !pending.isEmpty {
            let next = pending.removeFirst()
            // Re-check we don't already have a fresh entry by hashing.
            let h = Self.stableHash(next.description)
            if let e = memory[next.key], e.descriptionHash == h { continue }
            guard inflight[next.key] == nil else { continue }
            spawn(key: next.key, description: next.description, kind: next.kind)
        }
    }

    // MARK: - Prompt + cleanup

    /// Single-sentence summary, prompt tailored per kind. Talk prompts
    /// bias toward "what will the audience learn"; speaker prompts bias
    /// toward "what is this person known for" so the result reads as a
    /// substitute for a missing job title rather than a TL;DR of their bio.
    private static func prompt(for description: String, kind: SummaryKind) -> String {
        switch kind {
        case .talk:
            return """
            Summarize this conference talk description in ONE sentence of
            about 15 words. Focus on what the audience will learn or what
            is demonstrated. Be concrete and concise. No hype, no
            marketing language, no leading phrases like "this talk" or
            "the speaker"—just the content. Do not add quotation marks.

            Description:
            \(description)
            """
        case .speaker:
            return """
            Summarize this conference speaker bio in ONE short fragment of
            about 10 words — like a job title or professional descriptor
            that reads naturally below the speaker's name. Capture what
            they do or are known for. No hype, no leading phrases like
            "this speaker" or "the bio"—just the substance. Do not add
            quotation marks. Do not end with a period.

            Bio:
            \(description)
            """
        }
    }

    /// Strip wrapping quotes, leading "Summary:" markers, trailing
    /// periods+spaces, and collapse newlines. Models occasionally
    /// hedge with prefatory text even when asked not to.
    private static func cleanup(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = ["Summary:", "summary:", "SUMMARY:", "Summary -", "Summary:"]
        for p in prefixes {
            if s.hasPrefix(p) { s = String(s.dropFirst(p.count)).trimmingCharacters(in: .whitespaces) }
        }
        if s.hasPrefix("\"") && s.hasSuffix("\"") {
            s = String(s.dropFirst().dropLast())
        }
        // Collapse any internal newlines so the summary fits on 1-2 lines.
        s = s.replacingOccurrences(of: "\n", with: " ")
        // Final whitespace squeeze.
        s = s.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
        return s
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey) else { return }
        // Try the current shape first; fall back to the legacy [Int: Entry]
        // shape from before the Speaker namespacing landed. Legacy entries
        // are folded into the new String-keyed map under their bare id —
        // matches the default summaryCacheKey for Content/Event so existing
        // talk summaries survive the upgrade.
        if let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) {
            self.memory = decoded
            Log.app.debug("TalkSummaryCache loaded \(decoded.count, privacy: .public) summaries")
            return
        }
        if let legacy = try? JSONDecoder().decode([Int: Entry].self, from: data) {
            self.memory = Dictionary(uniqueKeysWithValues: legacy.map { (String($0.key), $0.value) })
            Log.app.debug("TalkSummaryCache migrated \(self.memory.count, privacy: .public) legacy entries")
            persist()
            return
        }
        // Corrupt payload — drop it.
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(memory)
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        } catch {
            Log.app.error("TalkSummaryCache persist failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func prune() {
        guard memory.count > maxEntries else { return }
        // Sort by createdAt asc, drop the oldest until we're back at cap.
        let sorted = memory.sorted { $0.value.createdAt < $1.value.createdAt }
        let toDrop = sorted.count - maxEntries
        for (key, _) in sorted.prefix(toDrop) {
            memory.removeValue(forKey: key)
        }
    }

    // MARK: - Hashing

    /// SHA256 of the UTF8 bytes, hex-encoded. Stable across launches
    /// (unlike `String.hashValue`, which is randomized).
    private static func stableHash(_ s: String) -> String {
        let digest = SHA256.hash(data: Data(s.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

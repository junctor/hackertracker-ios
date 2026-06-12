//
//  SharedScheduleStore.swift
//  hackertracker
//
//  Combined "Bookmarks across conferences" feature. Available only when:
//   1. At least two conferences in ConferencesViewModel.conferences have
//      overlapping date ranges (a HIG-DEFCON week with DC + BSidesLV +
//      BlackHat simultaneously is the motivating use case).
//   2. The local Bookmarks Core Data store contains event IDs that match
//      events in at least two of those overlapping conferences.
//
//  The store fetches content one-shot per overlapping conference (vs the
//  long-lived snapshot listeners InfoViewModel uses for the active
//  conference) because cross-conference data is rarely-edited and the
//  one-shot path is simpler. Firestore's per-device offline cache covers
//  repeat visits.
//
//  Caveat: event IDs aren't guaranteed globally unique across conferences
//  in this schema. If a bookmark ID collides between two conferences,
//  both rows surface in the combined view -- the conference badge on
//  each row lets the user pick the one they meant.
//

import Foundation
import FirebaseFirestore
import Observation

@Observable
@MainActor
final class SharedScheduleStore {

    /// One bookmarked event tagged with its source conference.
    struct Entry: Identifiable {
        let event: Event
        let conferenceCode: String
        let conferenceName: String
        var id: String { "\(conferenceCode)/\(event.id)" }
    }

    /// All matching entries, sorted ascending by event begin timestamp.
    var entries: [Entry] = []

    /// Conferences that contributed at least one entry. The combined view is
    /// considered "available" only when this contains 2 or more.
    var sourceConferences: [Conference] = []

    /// True iff the combined view should be reachable from InfoView.
    var isAvailable: Bool { sourceConferences.count >= 2 }

    /// Last refresh state, used to gate spinner UI in the view.
    var isLoading: Bool = false

    @ObservationIgnored private let db = Firestore.firestore()

    /// Refresh entries against the given bookmark IDs and the full conference
    /// list (typically `ConferencesViewModel.conferences`). Safe to call
    /// repeatedly; idempotent.
    func refresh(bookmarkIds: Set<Int>, allConferences: [Conference]) async {
        // 1. Find conferences whose date ranges overlap with at least one other.
        let overlapping = Self.overlappingConferences(from: allConferences)
        guard overlapping.count >= 2, !bookmarkIds.isEmpty else {
            // Not enough conferences to ever combine, or no bookmarks at all.
            self.entries = []
            self.sourceConferences = []
            return
        }

        self.isLoading = true
        defer { self.isLoading = false }

        // 2. Fan out: fetch each overlapping conference's content in parallel,
        //    convert sessions to Event objects, filter by bookmarkIds.
        //    Conference isn't Sendable (the @DocumentID Firestore wrapper), so
        //    pass only the code+name (Strings) across the actor boundary and
        //    let the main actor re-associate.
        let confLookup = Dictionary(uniqueKeysWithValues: overlapping.map { ($0.code, $0) })
        let codeAndName: [(code: String, name: String)] = overlapping.map { ($0.code, $0.name) }

        var allEntries: [Entry] = []
        var contributingConfs: [Conference] = []

        let fetchResults: [(String, [Event])] = await withTaskGroup(of: (String, [Event]).self) { group in
            for pair in codeAndName {
                let code = pair.code
                let ids = bookmarkIds
                group.addTask {
                    let events = await self.fetchBookmarkedEvents(
                        conferenceCode: code,
                        bookmarkIds: ids
                    )
                    return (code, events)
                }
            }
            var collected: [(String, [Event])] = []
            for await pair in group {
                collected.append(pair)
            }
            return collected
        }

        for (code, events) in fetchResults {
            guard !events.isEmpty, let conf = confLookup[code] else { continue }
            contributingConfs.append(conf)
            for ev in events {
                allEntries.append(Entry(
                    event: ev,
                    conferenceCode: conf.code,
                    conferenceName: conf.name
                ))
            }
        }

        // 3. Require at least 2 distinct contributing conferences.
        guard contributingConfs.count >= 2 else {
            self.entries = []
            self.sourceConferences = []
            return
        }

        // 4. Sort by start time ascending.
        self.entries = allEntries.sorted { $0.event.beginTimestamp < $1.event.beginTimestamp }
        self.sourceConferences = contributingConfs.sorted { $0.startTimestamp < $1.startTimestamp }
    }

    // MARK: - Helpers

    /// Conferences whose `[start_timestamp, end_timestamp)` range overlaps
    /// with at least one other conference in the input.
    static func overlappingConferences(from confs: [Conference]) -> [Conference] {
        guard confs.count >= 2 else { return [] }
        var hits: Set<String> = []
        for i in confs.indices {
            for j in (i + 1)..<confs.endIndex {
                let a = confs[i]
                let b = confs[j]
                // Half-open interval overlap test: matches Phase 1 bookmarkConflicts.
                if a.startTimestamp < b.endTimestamp && b.startTimestamp < a.endTimestamp {
                    hits.insert(a.code)
                    hits.insert(b.code)
                }
            }
        }
        return confs.filter { hits.contains($0.code) }
    }

    /// One-shot fetch of every content document in a conference's `content`
    /// collection, returning the Event-flattened subset whose `id` is in
    /// `bookmarkIds`. Mirrors the logic in InfoViewModel.fetchContent.
    private func fetchBookmarkedEvents(conferenceCode: String,
                                       bookmarkIds: Set<Int>) async -> [Event] {
        do {
            let snap = try await db.collection("conferences")
                .document(conferenceCode)
                .collection("content")
                .getDocuments()
            var events: [Event] = []
            var seen: Set<Int> = []
            for doc in snap.documents {
                guard let content = try? doc.data(as: Content.self) else { continue }
                for session in content.sessions where bookmarkIds.contains(session.id) {
                    guard !seen.contains(session.id) else { continue }
                    seen.insert(session.id)
                    let event = Event(
                        id: session.id,
                        contentId: content.id,
                        description: content.description,
                        beginTimestamp: session.beginTimestamp,
                        endTimestamp: session.endTimestamp,
                        title: content.title,
                        locationId: session.locationId,
                        people: content.people,
                        tagIds: content.tagIds,
                        relatedIds: content.relatedIds
                    )
                    events.append(event)
                }
            }
            return events
        } catch {
            Log.firestore.error("shared schedule fetch failed for \(conferenceCode, privacy: .public): \(error, privacy: .public)")
            CrashReport.record(error, context: ["op": "fetchSharedSchedule", "code": conferenceCode])
            return []
        }
    }
}

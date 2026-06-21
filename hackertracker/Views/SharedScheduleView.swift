//
//  SharedScheduleView.swift
//  hackertracker
//
//  Combined "Bookmarks across conferences" screen. Reached from InfoView
//  only when SharedScheduleStore.isAvailable.
//
//  Renders entries grouped by day (rendered in device-current timezone so
//  cross-conference comparison reads naturally), with a per-row conference
//  badge so attendees can tell DC32 from BSidesLV at a glance.
//

import SwiftUI

struct SharedScheduleView: View {
    @Environment(SharedScheduleStore.self) private var sharedSchedule
    @Environment(ThemeManager.self) private var themeManager
    let dfu = DateFormatterUtility.shared

    // Polish parity with the schedule.
    @State private var jumpTarget: String?

    // Group entries by day-string (in device-current TZ for cross-conference
    // clarity), preserving the sorted order within each day.
    private var grouped: [(day: String, entries: [SharedScheduleStore.Entry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        var order: [String] = []
        var bucket: [String: [SharedScheduleStore.Entry]] = [:]
        for entry in sharedSchedule.entries {
            let key = formatter.string(from: entry.event.beginTimestamp)
            if bucket[key] == nil {
                bucket[key] = []
                order.append(key)
            }
            bucket[key]!.append(entry)
        }
        return order.map { ($0, bucket[$0] ?? []) }
    }

    @ViewBuilder private var jumpMenu: some View {
        Menu {
            Button {
                jumpTarget = "__top"
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                jumpTarget = "__bottom"
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }

    var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility tz changes.
        let _ = dfu.tzGeneration

        ScrollView {
            if sharedSchedule.entries.isEmpty {
                if sharedSchedule.isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else {
                    ContentUnavailableView(
                        "No Combined Bookmarks",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Bookmark events in at least two overlapping conferences to see them combined here.")
                    )
                    .padding(.top, 60)
                }
            } else {
                ScrollViewReader { proxy in
                    LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
                        Color.clear.frame(height: 1).id("__top")
                        ForEach(grouped, id: \.day) { group in
                            Section(header: dayHeader(group.day)) {
                                ForEach(group.entries) { entry in
                                    SharedScheduleRow(entry: entry)
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                        Color.clear.frame(height: 1).id("__bottom")
                    }
                    .onChange(of: jumpTarget) { _, target in
                        guard let target else { return }
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                        DispatchQueue.main.async { jumpTarget = nil }
                    }
                }
                .iPadReadableContent()
            }
        }
        .overlay(alignment: .bottom) {
            if !sharedSchedule.entries.isEmpty {
                HStack {
                    Spacer()
                    jumpMenu
                        .font(themeManager.title2Font)
                        .foregroundStyle(.primary)
                        .frame(width: 48, height: 48)
                        .background(.regularMaterial, in: Circle())
                        .accessibilityLabel("Jump")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .navigationTitle("Combined Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .analyticsScreen(name: "SharedScheduleView")
    }

    @ViewBuilder
    private func dayHeader(_ day: String) -> some View {
        Text(day.uppercased())
            .font(themeManager.subheadlineFont)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
    }
}

/// One row in the combined schedule. Renders the source conference as a
/// small color-tinted badge so attendees can disambiguate across DC,
/// BSidesLV, BlackHat, etc. without studying the time block.
struct SharedScheduleRow: View {
    let entry: SharedScheduleStore.Entry
    let dfu = DateFormatterUtility.shared
    @AppStorage("show24hourtime") var show24hourtime: Bool = true

    /// Format event start time in the device-current zone so the combined
    /// view stays self-consistent regardless of which conference the row
    /// came from.
    /// Perf D: reuse two static formatters keyed by show24hourtime
    /// rather than allocating per row.
    private func timeString(_ date: Date) -> String {
        let f = show24hourtime ? SharedScheduleFormatters.h24 : SharedScheduleFormatters.h12
        return f.string(from: date)
    }

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        let _ = dfu.tzGeneration
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.conferenceName)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ThemeColors.blue.opacity(0.25))
                    .foregroundStyle(.primary)
                    .cornerRadius(6)
                Spacer()
                Text("\(timeString(entry.event.beginTimestamp)) – \(timeString(entry.event.endTimestamp))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.event.title)
                .font(.headline)
                .multilineTextAlignment(.leading)
            // Note: Event.people is [Person] (id+sortOrder+tagId only). Rendering
            // speaker names here would require a cross-conference speaker lookup
            // we don't currently maintain. Skip for now -- the title + conference
            // badge + time block is enough to identify each entry.
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.cardSurface)
        .cornerRadius(12)
    }
}

/// Perf D: shared formatter pool for SharedScheduleRow. Row is
/// rendered on the main actor so concurrent access is impossible.
@MainActor
private enum SharedScheduleFormatters {
    static let h24: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone.current
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    static let h12: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = TimeZone.current
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

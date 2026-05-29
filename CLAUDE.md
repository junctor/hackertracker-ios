# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

HackerTracker iOS — SwiftUI app for DEF CON / hacker conferences. Bundle id `org.beezle.hackertracker`, current `MARKETING_VERSION` 5.9, deployment target iOS 16.0, Swift 5.0. Targets: `hackertracker` (app), `hackertrackerTests`, `hackertrackerUITests`.

## Build / test

No CocoaPods/SPM manifest at the repo root — dependencies are managed inside the Xcode project (SwiftPM packages declared in `hackertracker.xcodeproj`).

```sh
# Build for simulator
xcodebuild -project hackertracker.xcodeproj -scheme hackertracker \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

# Unit + UI tests
xcodebuild -project hackertracker.xcodeproj -scheme hackertracker \
  -destination 'platform=iOS Simulator,name=iPhone 15' test

# Single test (XCTest -only-testing format: Target/Class/method)
xcodebuild -project hackertracker.xcodeproj -scheme hackertracker \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:hackertrackerTests/SomeTests/testSomething test

# Lint (config at .swiftlint.yml, scoped to hackertracker/)
swiftlint
```

SwiftLint disables: `identifier_name`, `line_length`, `type_name`, `trailing_whitespace`, `void_function_in_ternary`. Warning threshold 10.

## Architecture

SwiftUI app with a Firestore-backed live-data layer and CoreData+CloudKit local persistence. The big picture spans several files:

- **Entry point** — `hackertracker/hackertrackerApp.swift` wires the `AppDelegate` (Firebase configure, APNs registration, FCM token relay via `NotificationCenter` as `FCMToken`) and injects the CoreData context into `ContentView`.
- **Root view** — `Views/ContentView.swift` owns the long-lived `@StateObject`s that the rest of the app reads via `@EnvironmentObject`: `SelectedConference`, `InfoViewModel`, `ConferencesViewModel`, `Theme`, `Filters`, and the `ToTop`/`ToBottom`/`ToCurrent`/`ToNext` scroll-command objects (subclasses of `GoToButton`) that child views observe to trigger scroll actions on the active tab. App settings live in `@AppStorage` (`conferenceCode`, `launchScreen`, `showHidden`, `showLocaltime`, `showNews`, `lightMode`, `colorMode`, `easterEgg`).
- **Data layer** — `ViewModels/InfoViewModel.swift` is the central hub. It opens Firestore `ListenerRegistration`s for the selected conference's documents, tags, locations, products, content, speakers, orgs, articles, menus, etc., publishing them as `@Published` arrays. Most views observe this single view model. `ViewModels/ConferencesViewModel.swift` lists conferences; `ViewModels/EventViewModel.swift` is event-scoped.
- **Local persistence** — `Persistence.swift` exposes `PersistenceController.shared` backed by `NSPersistentCloudKitContainer(name: "hackertracker")`. CoreData is used primarily for `Bookmarks` (cross-device sync via CloudKit). User-driven bookmark/cart/feedback logic lives in `Utils/BookmarkUtility.swift`, `Utils/CartUtility.swift`, `Utils/FeedbackUtility.swift`.
- **Models** — Plain `Codable`/`Identifiable` structs in `hackertracker/Models/` map 1:1 to Firestore documents (`Conference`, `Event`, `Speaker`, `Location`, `Content`, `Organization`, `Product`, `Tag`, `Menu`, `FAQ`, `Article`, `FeedbackForm`, `Document`, `Map`, `Vendor`, `UserEvent`, `Bookmark`, `EventType`). `Utils/ModelExt.swift` holds shared extensions.
- **Views** — Tab-based; each top-level tab (`InfoView`, `EventsView`, `ScheduleView`, `MoreMenu`, etc.) lives in `Views/`. `EventsView` and `InfoView` are the largest (~16-28KB) and integrate filtering (`FiltersView` + `Filters`), search (`GlobalSearchView` + `Utils/Searchable.swift`), and the scroll-command objects from `ContentView`.
- **Utilities** — Date handling is centralized in `Utils/DateFormatterUtility.swift` (handles conference-local vs device-local time toggled by `showLocaltime`). Theming in `Utils/Theme.swift` + `Utils/ColorUtility.swift`. Local notifications in `Utils/NotificationUtility.swift` (uses `@AppStorage("notifyAt")` minutes-before from `InfoViewModel`).

## Dependencies (SwiftPM via Xcode project)

- `firebase-ios-sdk` — Firestore, Storage, Analytics, Messaging (FCM/APNs), InAppMessaging
- `Kingfisher` — image loading
- `swift-markdown-ui` (MarkdownUI) — markdown rendering for content/news

## Conventions

- Recent commit history shows a deliberate removal of SwiftUI `List` containers (commit `5bfbe92`: "remove of all List to prevent data crashes"). Prefer `ScrollView` + `LazyVStack` patterns when adding new collection UIs in this codebase.
- Bump `MARKETING_VERSION` in `hackertracker.xcodeproj/project.pbxproj` (both Debug + Release configs) when cutting a release; commit message style is `vX.Y-Z updates for <event>` (see `74b5568`).

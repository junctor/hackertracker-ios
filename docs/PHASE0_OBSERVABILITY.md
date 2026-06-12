# Phase 0 — Observability

Landed changes:

- **`hackertracker/Utils/Logger+HT.swift`** — new file. Centralized `os.Logger` instances under the `Log.*` namespace and a `CrashReport` shim that records non-fatals to Firebase Crashlytics when the SDK is linked.
- **`hackertrackerApp.swift`** — Crashlytics collection enabled on launch (guarded by `canImport`), authorization-request errors now logged + reported, FCM token presence logged instead of the token value being printed.
- **`Persistence.swift`** — Core Data store-load failures now log + `CrashReport.record(...)` instead of `fatalError`. Recovery logic (wipe + reseed) is queued for Phase 1.
- **All `print(...)` calls swept** across `Utils/`, `ViewModels/`, and `Views/` (~120 sites) to `Log.<category>.<level>(...)` with `privacy: .public` where appropriate. Error paths also call `CrashReport.record(error, context: [...])`.

## One manual step left: add the FirebaseCrashlytics product

The Firebase SPM package reference is already in `hackertracker.xcodeproj`. To enable Crashlytics:

1. Open the project in Xcode.
2. Select the `hackertracker` target → **General** → **Frameworks, Libraries, and Embedded Content** → **+**.
3. Choose `firebase-ios-sdk` → **FirebaseCrashlytics**. Add.
4. Target → **Build Phases** → **+** → **New Run Script Phase**. Move it after **Embed Frameworks**. Script:
   ```sh
   "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
   ```
   Input files:
   ```
   ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
   $(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)
   ```
5. Clean build folder, rebuild. The `#if canImport(FirebaseCrashlytics)` guards in `Logger+HT.swift` and `hackertrackerApp.swift` will then compile in the real bridge automatically — no Swift code changes needed.

## What you'll see in Console.app / Crashlytics

Filter Console.app by subsystem `org.beezle.hackertracker`. Categories: `app`, `firestore`, `coredata`, `notifications`, `bookmarks`, `cart`, `ui`, `network`.

Non-fatal Crashlytics reports are recorded with a `context` dict for every Firestore decode failure, Core Data save/load failure, bookmark/cart op failure, and notification authorization failure.

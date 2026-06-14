//
//  CustomEventUtility.swift
//  hackertracker
//
//  CRUD + fetch helpers for the local `CustomEvent` entity. Mirrors the
//  shape of `BookmarkUtility` so the rest of the app can use the same
//  call pattern. Persistence lives in the same NSPersistentCloudKitContainer
//  Bookmarks uses, so saved custom events sync across the user's
//  iCloud-signed-in devices for free.
//

import CoreData
import Foundation
import SwiftUI

enum CustomEventUtility {
    // MARK: - Notification helpers

    /// Schedule or refresh a notification for the supplied event.
    /// No-op when notificationsEnabled is false or when the event
    /// is missing required fields. Uses the global "Before Event"
    /// minutes setting (@AppStorage("notifyAt")), defaulting to 20
    /// to match the rest of the app.
    private static func scheduleNotificationIfNeeded(_ event: CustomEvent) {
        guard event.notificationsEnabled,
              let begin = event.beginTimestamp,
              let title = event.title else { return }
        let notifyAt = UserDefaults.standard.object(forKey: "notifyAt") as? Int ?? 20
        let date = begin.addingTimeInterval(Double(-notifyAt) * 60)
        let id = notificationID(for: event)
        let location = event.location ?? ""
        // Cancel any previous schedule under the same id, then re-add.
        NotificationUtility.removeNotification(id: id)
        NotificationUtility.scheduleNotification(date: date, id: id, title: title, location: location)
    }

    /// Remove any pending notification associated with the supplied
    /// event. Safe to call regardless of notificationsEnabled — the
    /// id is deterministic so we always know what to cancel.
    private static func cancelNotification(_ event: CustomEvent) {
        NotificationUtility.removeNotification(id: notificationID(for: event))
    }

    // MARK: - Create

    /// Insert a new CustomEvent with the supplied fields. Returns the
    /// new managed object so the caller can navigate to a detail view
    /// without an extra fetch.
    @discardableResult
    static func create(
        context: NSManagedObjectContext,
        title: String,
        eventDescription: String?,
        beginTimestamp: Date,
        endTimestamp: Date,
        location: String?,
        notes: String?,
        conferenceCodes: [String],
        colorHex: String?,
        notificationsEnabled: Bool
    ) -> CustomEvent? {
        let now = Date()
        let event = CustomEvent(context: context)
        event.id = UUID()
        event.title = title
        event.eventDescription = eventDescription
        event.beginTimestamp = beginTimestamp
        event.endTimestamp = endTimestamp
        event.location = location
        event.notes = notes
        // NSArray of NSString — stored via NSSecureUnarchiveFromDataTransformer.
        event.conferenceCodes = conferenceCodes as NSArray
        event.colorHex = colorHex
        event.notificationsEnabled = notificationsEnabled
        event.createdAt = now
        event.updatedAt = now
        guard save(context: context, op: "create") else { return nil }
        scheduleNotificationIfNeeded(event)
        return event
    }

    // MARK: - Update

    /// Mutate the supplied event in place and persist. Caller is responsible
    /// for setting the fields it wants to change before invoking; this
    /// helper just stamps `updatedAt` and saves.
    @discardableResult
    static func touchAndSave(context: NSManagedObjectContext, event: CustomEvent) -> Bool {
        event.updatedAt = Date()
        let ok = save(context: context, op: "update")
        if ok {
            if event.notificationsEnabled {
                scheduleNotificationIfNeeded(event)
            } else {
                cancelNotification(event)
            }
        }
        return ok
    }

    // MARK: - Delete

    @discardableResult
    static func delete(context: NSManagedObjectContext, event: CustomEvent) -> Bool {
        cancelNotification(event)
        context.delete(event)
        return save(context: context, op: "delete")
    }

    @discardableResult
    static func delete(context: NSManagedObjectContext, id: UUID) -> Bool {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "CustomEvent")
        fr.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            if let rows = try context.fetch(fr) as? [NSManagedObject] {
                for r in rows {
                    if let ce = r as? CustomEvent { cancelNotification(ce) }
                    context.delete(r)
                }
            }
        } catch {
            Log.coreData.error("CustomEvent delete by id fetch failed: \(error as NSError, privacy: .public)")
            CrashReport.record(error as NSError, context: ["op": "deleteCustomEventByID"])
            return false
        }
        return save(context: context, op: "deleteByID")
    }

    // MARK: - Fetch

    /// All custom events, sorted by begin time ascending. Schedule
    /// integration calls this and folds the result into the existing
    /// Event pipeline.
    static func all(context: NSManagedObjectContext) -> [CustomEvent] {
        let fr = NSFetchRequest<CustomEvent>(entityName: "CustomEvent")
        fr.sortDescriptors = [NSSortDescriptor(key: "beginTimestamp", ascending: true)]
        do {
            return try context.fetch(fr)
        } catch {
            Log.coreData.error("CustomEvent fetch all failed: \(error as NSError, privacy: .public)")
            CrashReport.record(error as NSError, context: ["op": "fetchAllCustomEvents"])
            return []
        }
    }

    /// Custom events that target the supplied conference code (i.e. its
    /// `conferenceCodes` array contains the code, OR the array is empty
    /// meaning "any conference"). Filter applied in memory because Core
    /// Data can't predicate over Transformable arrays.
    static func forConference(context: NSManagedObjectContext, code: String) -> [CustomEvent] {
        all(context: context).filter { event in
            guard let raw = event.conferenceCodes as? [String], !raw.isEmpty else {
                return true // empty array → applies to every conference
            }
            return raw.contains(code)
        }
    }

    // MARK: - Helpers

    /// Lookup helper used by the form's "applies to" multi-select.
    static func conferenceCodes(of event: CustomEvent) -> [String] {
        (event.conferenceCodes as? [String]) ?? []
    }

    /// A deterministic Int derived from the UUID's first 4 bytes so the
    /// existing NotificationUtility (which keys by Int32-castable Int)
    /// can be reused without breaking on UUIDs. Top bit cleared so the
    /// result fits in an Int32 positive range, avoiding collisions with
    /// Firestore event ids that are also positive Ints.
    ///
    /// The high-bit-set range (0x8000_0000..<0xFFFF_FFFF mapped via |=)
    /// is reserved for custom events; Firestore allocates ids out of
    /// the lower half, so the two name-spaces don't collide.
    static func notificationID(for event: CustomEvent) -> Int {
        guard let uuid = event.id else { return 0 }
        let bytes = withUnsafeBytes(of: uuid.uuid) { Array($0.prefix(4)) }
        var v: UInt32 = 0
        for b in bytes { v = (v << 8) | UInt32(b) }
        v &= 0x7FFF_FFFF      // ensure non-negative when cast to Int32
        v |= 0x4000_0000      // mark as a custom-event id (top bit of 32-bit range)
        return Int(v)
    }

    // MARK: - Save plumbing

    @discardableResult
    private static func save(context: NSManagedObjectContext, op: String) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            let nsError = error as NSError
            Log.coreData.error("CustomEvent \(op, privacy: .public) save failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "customEvent_\(op)"])
            return false
        }
    }
}

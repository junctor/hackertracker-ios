//
//  NotesUtility.swift
//  hackertracker
//
//  CRUD + fetch for the shared `Note` Core Data entity. One table
//  serves Firestore events, Firestore content, and locally-stored
//  custom events; the (`targetID`, `targetKind`) pair disambiguates.
//
//  Lives in the same NSPersistentCloudKitContainer Bookmarks and
//  CustomEvents already use, so notes sync to the user's iCloud-
//  signed-in devices for free.
//

import CoreData
import Foundation

enum NoteKind: String {
    case event = "event"
    case content = "content"
    case customEvent = "customEvent"
}

enum NotesUtility {

    // MARK: - Fetch

    /// Return the single Note (if any) attached to the supplied target.
    /// We treat Notes as one-per-target; if duplicates ever land (e.g.
    /// a CloudKit merge of two devices each creating their own row),
    /// the most-recently-updated wins and the others are cleaned up.
    static func note(context: NSManagedObjectContext, targetID: Int, kind: NoteKind) -> Note? {
        let fr = NSFetchRequest<Note>(entityName: "Note")
        fr.predicate = NSPredicate(format: "targetID == %d AND targetKind == %@", Int32(targetID), kind.rawValue)
        fr.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        do {
            let rows = try context.fetch(fr)
            if rows.count > 1 {
                // Dedup: keep the freshest, drop the rest.
                for stale in rows.dropFirst() {
                    context.delete(stale)
                }
                _ = save(context: context, op: "noteDedup")
            }
            return rows.first
        } catch {
            Log.coreData.error("Note fetch failed: \(error as NSError, privacy: .public)")
            CrashReport.record(error as NSError, context: ["op": "fetchNote"])
            return nil
        }
    }

    // MARK: - Write

    /// Insert-or-update the note body for the supplied target. Empty
    /// or whitespace-only bodies delete the row instead — there's no
    /// reason to persist an empty note, and it lets the inline UI fall
    /// back to its "Add a note" affordance cleanly.
    @discardableResult
    static func upsert(
        context: NSManagedObjectContext,
        targetID: Int,
        kind: NoteKind,
        body: String
    ) -> Note? {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            delete(context: context, targetID: targetID, kind: kind)
            return nil
        }
        let now = Date()
        if let existing = note(context: context, targetID: targetID, kind: kind) {
            existing.body = body
            existing.updatedAt = now
            return save(context: context, op: "noteUpdate") ? existing : nil
        }
        let note = Note(context: context)
        note.id = UUID()
        note.targetID = Int32(targetID)
        note.targetKind = kind.rawValue
        note.body = body
        note.createdAt = now
        note.updatedAt = now
        return save(context: context, op: "noteInsert") ? note : nil
    }

    @discardableResult
    static func delete(context: NSManagedObjectContext, targetID: Int, kind: NoteKind) -> Bool {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        fr.predicate = NSPredicate(format: "targetID == %d AND targetKind == %@", Int32(targetID), kind.rawValue)
        do {
            if let rows = try context.fetch(fr) as? [NSManagedObject] {
                for r in rows { context.delete(r) }
            }
        } catch {
            Log.coreData.error("Note delete fetch failed: \(error as NSError, privacy: .public)")
            CrashReport.record(error as NSError, context: ["op": "deleteNoteFetch"])
            return false
        }
        return save(context: context, op: "noteDelete")
    }

    // MARK: - Save plumbing

    @discardableResult
    private static func save(context: NSManagedObjectContext, op: String) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            let nsError = error as NSError
            Log.coreData.error("Note \(op, privacy: .public) save failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "note_\(op)"])
            return false
        }
    }
}

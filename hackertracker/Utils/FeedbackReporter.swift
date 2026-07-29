//
//  FeedbackReporter.swift
//  hackertracker
//
//  Service layer for the "report an issue" feedback flow. Builds a
//  deterministic payload (`makeReport`) for testability and POSTs it
//  to the feedback endpoint (`send`). Includes an anonymous,
//  app-generated device identifier stored in the Keychain.
//

import Foundation
import Security

enum ReportObjectType: String {
    case content, org, person, document
}

struct ReportError: Error {
    let message: String
}

struct FeedbackReport: Encodable {
    let message: String
    let conferenceId: Int
    let conferenceName: String
    let objectType: String
    let objectId: Int
    let reportTimestamp: String
    let reportUuid: String
    let client: String
    let deviceIdentifier: String

    enum CodingKeys: String, CodingKey {
        case message
        case conferenceId = "conference_id"
        case conferenceName = "conference_name"
        case objectType = "object_type"
        case objectId = "object_id"
        case reportTimestamp = "report_timestamp"
        case reportUuid = "report_uuid"
        case client = "client"
        case deviceIdentifier = "device_identifier"
    }
}

/// Anonymous, app-generated install identifier. Random UUID created once
/// and stored in the Keychain (not device/IDFV-derived) — no tracking.
enum ReportDeviceIdentifier {
    private static let account = "org.beezle.hackertracker.reportDeviceID"

    static func current() -> String {
        if let existing = read() { return existing }
        let new = UUID().uuidString
        save(new)
        return new
    }

    private static func read() -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    private static func save(_ value: String) {
        let data = Data(value.utf8)
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }
}

enum FeedbackReporter {
    private static let endpoint = URL(string: "https://feedback1.junctorconf.net/reporting.php")!

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static func clientString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "HackerTracker iOS \(v) (\(b))"
    }

    /// Deterministic builder (injectable stamps for tests).
    static func makeReport(message: String, conferenceId: Int, conferenceName: String,
                           objectType: ReportObjectType, objectId: Int,
                           now: Date, uuid: String, deviceID: String) -> FeedbackReport {
        FeedbackReport(
            message: message,
            conferenceId: conferenceId,
            conferenceName: conferenceName,
            objectType: objectType.rawValue,
            objectId: objectId,
            reportTimestamp: timestampFormatter.string(from: now),
            reportUuid: uuid,
            client: clientString(),
            deviceIdentifier: deviceID
        )
    }

    static func send(message: String, conferenceId: Int, conferenceName: String,
                     objectType: ReportObjectType, objectId: Int) async -> Result<Void, ReportError> {
        let report = makeReport(message: message, conferenceId: conferenceId, conferenceName: conferenceName,
                                objectType: objectType, objectId: objectId,
                                now: Date(), uuid: UUID().uuidString,
                                deviceID: ReportDeviceIdentifier.current())
        do {
            var req = URLRequest(url: endpoint)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(report)
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                Log.network.error("feedback POST non-2xx")
                return .failure(ReportError(message: "The report couldn’t be sent. Please try again."))
            }
            return .success(())
        } catch {
            Log.network.error("feedback POST failed: \(String(describing: error), privacy: .public)")
            return .failure(ReportError(message: "The report couldn’t be sent. Please try again."))
        }
    }
}

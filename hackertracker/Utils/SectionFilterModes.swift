import Foundation

/// Per-tagtype-section Any/All modes for the Schedule + All Content filter.
/// Persisted as a JSON object [tagTypeId(String): "any"|"all"] in a single
/// AppStorage string. Sections with no stored entry default to `.any`.
struct SectionFilterModes: Equatable {
    private var modes: [Int: FilterMatchMode]

    init(json: String) {
        guard let data = json.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: String].self, from: data) else {
            modes = [:]; return
        }
        modes = raw.reduce(into: [:]) { acc, kv in
            if let id = Int(kv.key), let mode = FilterMatchMode(rawValue: kv.value) {
                acc[id] = mode
            }
        }
    }

    var jsonString: String {
        let raw = modes.reduce(into: [String: String]()) { $0[String($1.key)] = $1.value.rawValue }
        guard let data = try? JSONEncoder().encode(raw),
              let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }

    func mode(for tagTypeId: Int) -> FilterMatchMode { modes[tagTypeId] ?? .any }
    mutating func setMode(_ mode: FilterMatchMode, for tagTypeId: Int) { modes[tagTypeId] = mode }

    /// Convenience: the raw dictionary, for passing into the predicate.
    var asDictionary: [Int: FilterMatchMode] { modes }
}

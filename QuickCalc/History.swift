import Foundation

struct HistoryEntry: Codable {
    let expression: String
    let display: String
    let clipboard: String
    let value: Double
}

/// Confirmed calculations, most recent first, kept in UserDefaults.
@MainActor
final class History {
    private static let key = "history"
    private static let limit = 100

    private(set) var entries: [HistoryEntry]
    var onChange: (() -> Void)?

    init() {
        let data = UserDefaults.standard.data(forKey: Self.key)
        entries = data.flatMap { try? JSONDecoder().decode([HistoryEntry].self, from: $0) } ?? []
    }

    /// The `ans` of the next calculation.
    var lastValue: Double? { entries.first?.value }

    func add(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > Self.limit { entries.removeLast(entries.count - Self.limit) }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(entries), forKey: Self.key)
        onChange?()
    }
}

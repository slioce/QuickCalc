import Foundation
import QuickCalcCore

/// ECB reference rates, downloaded a few times a day at most and cached for offline use.
@MainActor
final class ExchangeRates {
    private struct Cache: Codable {
        let rates: CurrencyRates
        let fetchedAt: Date
    }

    private static let key = "exchangeRates"
    private static let url = URL(string: CurrencyRates.ecbURL)!
    /// The ECB publishes once per working day, around 16:00 CET.
    private static let maxAge: TimeInterval = 6 * 3600
    /// When offline, don't retry on every panel opening.
    private static let retryInterval: TimeInterval = 15 * 60

    private(set) var current: CurrencyRates?
    var onUpdate: (() -> Void)?
    private var fetchedAt: Date?
    private var lastAttempt = Date.distantPast
    private var isFetching = false

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let cache = try? JSONDecoder().decode(Cache.self, from: data) {
            current = cache.rates
            fetchedAt = cache.fetchedAt
        }
    }

    func refreshIfNeeded() {
        let now = Date()
        if let fetchedAt, now.timeIntervalSince(fetchedAt) < Self.maxAge { return }
        guard !isFetching, now.timeIntervalSince(lastAttempt) > Self.retryInterval else { return }
        lastAttempt = now
        isFetching = true

        Task {
            defer { isFetching = false }
            guard let rates = await Self.download(from: Self.url) else { return }
            let cache = Cache(rates: rates, fetchedAt: Date())
            current = rates
            fetchedAt = cache.fetchedAt
            UserDefaults.standard.set(try? JSONEncoder().encode(cache), forKey: Self.key)
            onUpdate?()
        }
    }

    private nonisolated static func download(from url: URL) async -> CurrencyRates? {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let xml = String(data: data, encoding: .utf8)
        else { return nil }
        return CurrencyRates.parseECB(xml)
    }
}

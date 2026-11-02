/// Daily reference rates of the European Central Bank.
public struct CurrencyRates: Codable, Equatable, Sendable {
    /// Reference day, "yyyy-MM-dd".
    public let date: String
    /// Units of each currency per 1 EUR.
    public let perEuro: [String: Double]

    public init(date: String, perEuro: [String: Double]) {
        self.date = date
        self.perEuro = perEuro
    }

    public static let ecbURL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"

    /// Parses the ECB feed at `ecbURL`; nil if it is not one.
    public static func parseECB(_ xml: String) -> CurrencyRates? {
        guard let day = xml.firstMatch(of: /time=['"](\d{4}-\d{2}-\d{2})['"]/) else { return nil }
        var rates: [String: Double] = ["EUR": 1]
        for match in xml.matches(of: /currency=['"]([A-Z]{3})['"]\s+rate=['"]([0-9.]+)['"]/) {
            if let rate = Double(match.2), rate > 0 { rates[String(match.1)] = rate }
        }
        guard rates.count > 1 else { return nil }
        return CurrencyRates(date: String(day.1), perEuro: rates)
    }
}

enum Currencies {
    /// Published daily by the ECB; known even before the first download so the error can say so.
    static let codes = [
        "EUR", "USD", "JPY", "CZK", "DKK", "GBP", "HUF", "PLN", "RON", "SEK", "CHF", "ISK", "NOK",
        "TRY", "AUD", "BRL", "CAD", "CNY", "HKD", "IDR", "ILS", "INR", "KRW", "MXN", "MYR", "NZD", "PHP",
        "SGD", "THB", "ZAR",
    ]

    /// Symbols and names in English and Italian. "pounds" is left out: it is just as often a weight.
    static let aliases: [String: [String]] = [
        "EUR": ["€", "euro", "euros"],
        "USD": ["$", "dollars", "dollar", "dollari", "dollaro"],
        "GBP": ["£", "sterling", "sterline", "sterlina"],
        "JPY": ["¥", "yen"],
        "CHF": ["francs", "franchi"],
    ]

    /// Base unit is the euro. Without a rate the factor is NaN, i.e. the currency is known but unavailable.
    static func definitions(rates: CurrencyRates?) -> [UnitDefinition] {
        let all = Set(codes).union(rates.map { Array($0.perEuro.keys) } ?? [])
        return all.sorted().map { code in
            let factor = rates?.perEuro[code].map { 1 / $0 } ?? (code == "EUR" ? 1 : .nan)
            return UnitDefinition([code] + (aliases[code] ?? []), .currency, factor)
        }
    }
}

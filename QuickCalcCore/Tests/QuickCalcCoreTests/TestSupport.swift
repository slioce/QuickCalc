@testable import QuickCalcCore

/// Writes expected output with "_" standing for the thin space that groups thousands.
func grouped(_ s: String) -> String {
    s.replacingOccurrences(of: "_", with: "\u{202F}")
}

/// Results with a decimal comma, unless a test asks for the decimal point.
func display(_ input: String, ans: Double? = nil, rates: CurrencyRates? = nil, mark: DecimalMark = .comma) throws -> String {
    try Calculator.evaluate(input, ans: ans, rates: rates, decimalMark: mark).display
}

func error(_ input: String, ans: Double? = nil, mark: DecimalMark = .comma) -> CalcError? {
    do {
        _ = try Calculator.evaluate(input, ans: ans, decimalMark: mark)
        return nil
    } catch {
        return error
    }
}

/// Fixed rates, so currency results don't depend on the day.
let sampleRates = CurrencyRates(date: "2026-10-30", perEuro: ["EUR": 1, "USD": 1.08, "GBP": 0.84, "JPY": 160])

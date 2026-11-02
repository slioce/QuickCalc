import Foundation

public struct CalcResult: Equatable, Sendable {
    /// The value reused as `ans`: unrounded, except money, which is kept in cents.
    public let value: Double
    /// Text shown to the user, with thousands grouping and unit.
    public let display: String
    /// Text for the clipboard: the number only, without grouping.
    public let clipboard: String
    /// For currency conversions, the reference day of the exchange rates ("yyyy-MM-dd").
    public let ratesDate: String?

    init(value: Double, display: String, clipboard: String, ratesDate: String? = nil) {
        self.value = value
        self.display = display
        self.clipboard = clipboard
        self.ratesDate = ratesDate
    }
}

public enum Calculator {
    /// Input starting with one of these continues from the previous result ("+22%").
    private static let chainingPrefixes: Set<Character> = ["+", "*", "/", "^", "×", "÷"]

    private enum Base: String {
        case hex, bin, oct, dec

        var radix: Int {
            switch self {
            case .hex: 16
            case .bin: 2
            case .oct: 8
            case .dec: 10
            }
        }

        var prefix: String {
            switch self {
            case .hex: "0x"
            case .bin: "0b"
            case .oct: "0o"
            case .dec: ""
            }
        }
    }

    /// Evaluates an expression, a unit or currency conversion ("5 km in mi") or a base conversion ("255 in hex").
    /// - Parameters:
    ///   - ans: the previous result, for `ans` and for input starting with an operator.
    ///   - rates: exchange rates for currency conversions; nil when not downloaded yet.
    ///   - decimalMark: separator of the results, and how a lone "1,234" is read.
    public static func evaluate(
        _ input: String, ans: Double? = nil, rates: CurrencyRates? = nil, decimalMark: DecimalMark = .current
    ) throws(CalcError) -> CalcResult {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = text.first else { throw .empty }
        if chainingPrefixes.contains(first) { text = "ans" + text }

        let context = Context(ans: ans, rates: rates, mark: decimalMark)
        if let (expression, target) = splitConversion(text) {
            if let base = Base(rawValue: target.lowercased()) {
                return try context.convert(expression, to: base)
            }
            return try context.convertUnits(expression, to: target)
        }
        return context.decimalResult(try context.compute(text))
    }

    /// "<expression> in|to|a <target>" → (expression, target). Expressions never contain
    /// these words, so any match is a conversion. "a" is Italian for "to".
    private static func splitConversion(_ text: String) -> (String, String)? {
        let words = text.split(separator: " ")
        guard words.count >= 3, ["in", "to", "a"].contains(words[words.count - 2].lowercased()) else { return nil }
        return (words.dropLast(2).joined(separator: " "), String(words[words.count - 1]))
    }

    private struct Context {
        let ans: Double?
        let rates: CurrencyRates?
        let mark: DecimalMark

        func compute(_ text: String) throws(CalcError) -> Double {
            let expr = try Parser.parse(Lexer.tokenize(text, decimalMark: mark))
            return try checked(Evaluator(ans: ans).evaluate(expr))
        }

        func checked(_ value: Double) throws(CalcError) -> Double {
            guard !value.isNaN else { throw .undefined }
            guard value.isFinite else { throw .overflow }
            return value
        }

        func decimalResult(_ value: Double, unit: String? = nil) -> CalcResult {
            let suffix = unit.map { " " + $0 } ?? ""
            return CalcResult(
                value: value,
                display: ResultFormatter.decimal(value, grouped: true, mark: mark) + suffix,
                clipboard: ResultFormatter.decimal(value, grouped: false, mark: mark)
            )
        }

        func convert(_ expression: String, to base: Base) throws(CalcError) -> CalcResult {
            let value = try compute(expression)
            if base == .dec {
                guard let n = Int64(exactly: value) else { return decimalResult(value) }
                return CalcResult(
                    value: value,
                    display: ResultFormatter.integer(n, grouped: true, mark: mark),
                    clipboard: ResultFormatter.integer(n, grouped: false, mark: mark)
                )
            }
            let n = try Integers.exact(value)
            let text = base.prefix + String(UInt64(bitPattern: n), radix: base.radix, uppercase: true)
            return CalcResult(value: value, display: text, clipboard: text)
        }

        func convertUnits(_ expression: String, to targetName: String) throws(CalcError) -> CalcResult {
            let catalog = UnitCatalog(rates: rates)
            guard let target = catalog.lookup(targetName) else { throw .unknownUnit(targetName) }
            guard let (amountText, source) = catalog.splitTrailingUnit(expression) ?? catalog.splitLeadingCurrency(expression) else {
                let word = String(expression.reversed().prefix(while: \.isLetter).reversed())
                if !word.isEmpty, !Constants.isKnown(word.lowercased()) { throw .unknownUnit(word) }
                throw .missingSourceUnit
            }
            guard source.dimension == target.dimension else {
                throw .incompatibleUnits(source.symbol, target.symbol)
            }
            for unit in [source, target] where !unit.isAvailable {
                throw rates == nil ? .exchangeRatesUnavailable : .noExchangeRate(unit.symbol)
            }

            let amount = amountText.trimmingCharacters(in: .whitespaces).isEmpty ? 1 : try compute(amountText)
            var value = try checked(target.fromBase(source.toBase(amount)))

            guard target.dimension == .currency else { return decimalResult(value, unit: target.symbol) }
            // Shown and copied in cents, so `ans` matches what the user sees.
            if abs(value) >= 0.01 { value = (value * 100).rounded() / 100 }
            return CalcResult(
                value: value,
                display: ResultFormatter.money(value, grouped: true, mark: mark) + " " + target.symbol,
                clipboard: ResultFormatter.money(value, grouped: false, mark: mark),
                ratesDate: rates?.date
            )
        }
    }
}

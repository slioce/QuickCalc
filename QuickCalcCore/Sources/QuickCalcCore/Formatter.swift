import Foundation

enum ResultFormatter {
    static let significantDigits = 12

    /// Thin-space grouping, at most 12 significant digits, scientific notation outside 1e-9 ..< 1e15.
    static func decimal(_ value: Double, grouped: Bool, mark: DecimalMark) -> String {
        let rounded = Double(String(format: "%.\(significantDigits)g", value)) ?? value
        guard rounded != 0 else { return "0" }

        let magnitude = abs(rounded)
        if magnitude >= 1e15 || magnitude < 1e-9 {
            return scientific(rounded, mark: mark)
        }

        let integerDigits = Int(floor(log10(magnitude))) + 1
        let fractionDigits = max(0, significantDigits - integerDigits)
        var text = String(format: "%.\(fractionDigits)f", rounded)
        if text.contains(".") {
            while text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix(".") { text.removeLast() }
        }
        return localized(text, grouped: grouped, mark: mark)
    }

    /// Two decimals for amounts of money; amounts below a cent keep their significant digits.
    static func money(_ value: Double, grouped: Bool, mark: DecimalMark) -> String {
        guard value != 0 else { return "0" + mark.separator + "00" }
        guard abs(value) >= 0.01, abs(value) < 1e15 else { return decimal(value, grouped: grouped, mark: mark) }
        return localized(String(format: "%.2f", value), grouped: grouped, mark: mark)
    }

    static func integer(_ value: Int64, grouped: Bool, mark: DecimalMark) -> String {
        localized(String(value), grouped: grouped, mark: mark)
    }

    /// "-1234.5" → "-1 234,5" or "-1 234.5"
    private static func localized(_ text: String, grouped: Bool, mark: DecimalMark) -> String {
        var digits = Substring(text)
        let negative = digits.hasPrefix("-")
        if negative { digits.removeFirst() }

        let parts = digits.split(separator: ".", omittingEmptySubsequences: false)
        var integerPart = String(parts[0])
        if grouped { integerPart = group(integerPart) }

        var result = (negative ? "-" : "") + integerPart
        if parts.count > 1 { result += mark.separator + parts[1] }
        return result
    }

    private static func group(_ digits: String) -> String {
        guard digits.count > 3 else { return digits }
        var result = ""
        for (offset, digit) in digits.enumerated() {
            if offset > 0, (digits.count - offset) % 3 == 0 { result.append(Lexer.groupingSpace) }
            result.append(digit)
        }
        return result
    }

    /// 1.23e+20 → "1,23e20" or "1.23e20"
    private static func scientific(_ value: Double, mark: DecimalMark) -> String {
        let text = String(format: "%.\(significantDigits - 1)e", value)
        let parts = text.split(separator: "e")
        var mantissa = String(parts[0])
        if mantissa.contains(".") {
            while mantissa.hasSuffix("0") { mantissa.removeLast() }
            if mantissa.hasSuffix(".") { mantissa.removeLast() }
        }
        let exponent = Int(parts[1]) ?? 0
        return mantissa.replacingOccurrences(of: ".", with: mark.separator) + "e\(exponent)"
    }
}

enum Token: Equatable {
    case number(Double)
    case identifier(String)
    case plus, minus, times, divide, power
    case percent, factorial, degree, squared, cubed
    case leftParen, rightParen, separator
    case bitAnd, bitOr, bitNot, shiftLeft, shiftRight
    case root
}

enum Lexer {
    /// Narrow no-break space: groups thousands in the output and is accepted back as input.
    static let groupingSpace: Character = "\u{202F}"

    static func tokenize(_ input: String, decimalMark: DecimalMark = .comma) throws(CalcError) -> [Token] {
        let chars = Array(input)
        var tokens: [Token] = []
        var i = 0

        while i < chars.count {
            let c = chars[i]
            let next = i + 1 < chars.count ? chars[i + 1] : nil

            if c.isWhitespace {
                i += 1
                continue
            }

            // A number starts with a digit, or with a separator followed by a digit (",5")
            // where an operand is expected, so that "max(pi,2)" keeps "," as a separator.
            let leadingSeparator = (c == "." || c == ",") && next?.isDigit == true && expectsOperand(after: tokens.last)
            if c.isDigit || leadingSeparator {
                tokens.append(.number(try number(chars, &i, decimalMark: decimalMark)))
                continue
            }

            if c.isLetter || c == "_" {
                var name = ""
                while i < chars.count, chars[i].isLetter || chars[i].isDigit || chars[i] == "_" {
                    name.append(chars[i])
                    i += 1
                }
                tokens.append(.identifier(name))
                continue
            }

            let token: Token
            switch c {
            case "+": token = .plus
            case "-", "−", "–": token = .minus
            case "*" where next == "*":
                token = .power
                i += 1
            case "*", "×", "·", "⋅": token = .times
            case "/", "÷", "∕": token = .divide
            case "^": token = .power
            case "%": token = .percent
            case "!": token = .factorial
            case "°": token = .degree
            case "²": token = .squared
            case "³": token = .cubed
            case "(": token = .leftParen
            case ")": token = .rightParen
            case ";", ",": token = .separator
            case "&": token = .bitAnd
            case "|": token = .bitOr
            case "~": token = .bitNot
            case "<" where next == "<":
                token = .shiftLeft
                i += 1
            case ">" where next == ">":
                token = .shiftRight
                i += 1
            case "√": token = .root
            default: throw .invalidCharacter(String(c))
            }
            tokens.append(token)
            i += 1
        }
        return tokens
    }

    private static func expectsOperand(after token: Token?) -> Bool {
        switch token {
        case .number, .identifier, .rightParen, .percent, .factorial, .degree, .squared, .cubed: false
        default: true
        }
    }

    private static func number(_ chars: [Character], _ i: inout Int, decimalMark: DecimalMark) throws(CalcError) -> Double {
        if chars[i] == "0", i + 1 < chars.count, let radix = radix(for: chars[i + 1]) {
            var j = i + 2
            var digits = ""
            while j < chars.count, let digit = chars[j].hexDigitValue, digit < radix {
                digits.append(chars[j])
                j += 1
            }
            guard !digits.isEmpty, let value = UInt64(digits, radix: radix) else { throw .invalidNumber }
            i = j
            // 64-bit literals are two's complement, so "-1 in hex" round-trips.
            return Double(Int64(bitPattern: value))
        }

        var mantissa = ""
        var j = i
        while j < chars.count {
            let c = chars[j]
            let next = j + 1 < chars.count ? chars[j + 1] : nil
            if c.isDigit {
                mantissa.append(c)
            } else if c == "." || c == "," {
                if next?.isDigit == true {
                    mantissa.append(c)
                } else {
                    // A trailing separator ("2,") is the user about to type decimals.
                    if next == nil, !mantissa.isEmpty { j += 1 }
                    break
                }
            } else if c == groupingSpace, next?.isDigit == true, !mantissa.isEmpty {
                // skip thousands grouping from our own output
            } else {
                break
            }
            j += 1
        }

        var exponent = ""
        if j < chars.count, chars[j] == "e" || chars[j] == "E" {
            var k = j + 1
            var sign = ""
            if k < chars.count, chars[k] == "+" || chars[k] == "-" {
                sign = String(chars[k])
                k += 1
            }
            var digits = ""
            while k < chars.count, chars[k].isDigit {
                digits.append(chars[k])
                k += 1
            }
            if !digits.isEmpty {
                exponent = "e" + sign + digits
                j = k
            }
        }

        i = j
        return try decimalValue(mantissa, exponent: exponent, decimalMark: decimalMark)
    }

    private static func radix(for c: Character) -> Int? {
        switch c {
        case "x", "X": 16
        case "b": 2
        case "o": 8
        default: nil
        }
    }

    /// Reads digits that may use "." or "," as decimal or thousands separator:
    /// with both present the last one is decimal; a separator repeated is thousands
    /// (groups of exactly 3 digits); a single separator is decimal, except that with a decimal point
    /// a single comma followed by 3 digits groups thousands ("1,234").
    private static func decimalValue(_ mantissa: String, exponent: String, decimalMark: DecimalMark) throws(CalcError) -> Double {
        let dots = mantissa.count(where: { $0 == "." })
        let commas = mantissa.count(where: { $0 == "," })
        var decimalSeparator: Character?
        var groupSeparator: Character?

        if dots > 0, commas > 0 {
            let last = mantissa.last(where: { $0 == "." || $0 == "," })!
            guard (last == "." ? dots : commas) == 1 else { throw .invalidNumber }
            decimalSeparator = last
            groupSeparator = last == "." ? "," : "."
        } else if decimalMark == .point, commas == 1, mantissa.split(separator: ",").last?.count == 3 {
            groupSeparator = ","
        } else if dots + commas == 1 {
            decimalSeparator = dots == 1 ? "." : ","
        } else if dots + commas > 1 {
            groupSeparator = dots > 0 ? "." : ","
        }

        var integerPart = Substring(mantissa)
        var fraction: Substring = ""
        if let decimalSeparator, let index = mantissa.firstIndex(of: decimalSeparator) {
            integerPart = mantissa[..<index]
            fraction = mantissa[mantissa.index(after: index)...]
        }
        if let groupSeparator {
            let groups = integerPart.split(separator: groupSeparator, omittingEmptySubsequences: false)
            guard let first = groups.first, (1...3).contains(first.count),
                  groups.dropFirst().allSatisfy({ $0.count == 3 })
            else { throw .invalidNumber }
            integerPart = Substring(groups.joined())
        }

        let text = (integerPart.isEmpty ? "0" : integerPart) + (fraction.isEmpty ? "" : "." + fraction) + exponent
        guard let value = Double(text) else { throw .invalidNumber }
        return value
    }
}

extension Character {
    var isDigit: Bool { isASCII && isWholeNumber }
}

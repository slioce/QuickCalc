indirect enum Expr: Equatable {
    case number(Double)
    case constant(String)
    case negate(Expr)
    case bitNot(Expr)
    case percent(Expr)
    case factorial(Expr)
    case degrees(Expr)
    case binary(BinaryOperator, Expr, Expr)
    case call(String, [Expr])
}

enum BinaryOperator {
    case add, subtract, multiply, divide, modulo, power
    case bitAnd, bitOr, bitXor, shiftLeft, shiftRight
}

/// Recursive descent, lowest precedence first:
/// `|` → `xor` → `&` → `<< >>` → `+ -` → `* / mod` (and implicit) → unary → `^` → postfix → primary.
struct Parser {
    private let tokens: [Token]
    private var index = 0

    static func parse(_ tokens: [Token]) throws(CalcError) -> Expr {
        var parser = Parser(tokens: tokens)
        let expr = try parser.bitOr()
        if parser.peek != nil { throw .invalidSyntax }
        return expr
    }

    private init(tokens: [Token]) {
        self.tokens = tokens
    }

    private var peek: Token? { index < tokens.count ? tokens[index] : nil }

    private func peekKeyword(_ keyword: String) -> Bool {
        if case .identifier(let name) = peek { name.lowercased() == keyword } else { false }
    }

    private mutating func advance() -> Token? {
        defer { index += 1 }
        return peek
    }

    private mutating func bitOr() throws(CalcError) -> Expr {
        var lhs = try bitXor()
        while peek == .bitOr {
            index += 1
            lhs = .binary(.bitOr, lhs, try bitXor())
        }
        return lhs
    }

    private mutating func bitXor() throws(CalcError) -> Expr {
        var lhs = try bitAnd()
        while peekKeyword("xor") {
            index += 1
            lhs = .binary(.bitXor, lhs, try bitAnd())
        }
        return lhs
    }

    private mutating func bitAnd() throws(CalcError) -> Expr {
        var lhs = try shift()
        while peek == .bitAnd {
            index += 1
            lhs = .binary(.bitAnd, lhs, try shift())
        }
        return lhs
    }

    private mutating func shift() throws(CalcError) -> Expr {
        var lhs = try additive()
        while let op: BinaryOperator = peek == .shiftLeft ? .shiftLeft : peek == .shiftRight ? .shiftRight : nil {
            index += 1
            lhs = .binary(op, lhs, try additive())
        }
        return lhs
    }

    private mutating func additive() throws(CalcError) -> Expr {
        var lhs = try multiplicative()
        while let op: BinaryOperator = peek == .plus ? .add : peek == .minus ? .subtract : nil {
            index += 1
            lhs = .binary(op, lhs, try multiplicative())
        }
        return lhs
    }

    private mutating func multiplicative() throws(CalcError) -> Expr {
        var lhs = try unary()
        while true {
            if peek == .times || peek == .divide {
                let op: BinaryOperator = advance() == .times ? .multiply : .divide
                lhs = .binary(op, lhs, try unary())
            } else if peekKeyword("mod") {
                index += 1
                lhs = .binary(.modulo, lhs, try unary())
            } else if startsImplicitOperand(peek) {
                lhs = .binary(.multiply, lhs, try power())
            } else {
                return lhs
            }
        }
    }

    /// "2pi", "3(4+1)", "2√9". Never a bare number, so "1 000" stays an error instead of 0.
    private func startsImplicitOperand(_ token: Token?) -> Bool {
        switch token {
        case .identifier(let name): !["mod", "xor"].contains(name.lowercased())
        case .leftParen, .root: true
        default: false
        }
    }

    private mutating func unary() throws(CalcError) -> Expr {
        switch peek {
        case .minus:
            index += 1
            return .negate(try unary())
        case .plus:
            index += 1
            return try unary()
        case .bitNot:
            index += 1
            return .bitNot(try unary())
        default:
            return try power()
        }
    }

    private mutating func power() throws(CalcError) -> Expr {
        let base = try postfix()
        guard peek == .power else { return base }
        index += 1
        return .binary(.power, base, try unary())
    }

    private mutating func postfix() throws(CalcError) -> Expr {
        var expr = try primary()
        while true {
            switch peek {
            case .factorial: expr = .factorial(expr)
            case .degree: expr = .degrees(expr)
            case .squared: expr = .binary(.power, expr, .number(2))
            case .cubed: expr = .binary(.power, expr, .number(3))
            case .percent:
                index += 1
                switch peek {
                case .number, .leftParen: throw .useModForRemainder
                default: expr = .percent(expr)
                }
                continue
            default:
                return expr
            }
            index += 1
        }
    }

    private mutating func primary() throws(CalcError) -> Expr {
        guard let token = advance() else { throw .incomplete }
        switch token {
        case .number(let value):
            return .number(value)
        case .leftParen:
            let expr = try bitOr()
            try closeParen()
            return expr
        case .root:
            return .call("sqrt", [try postfix()])
        case .identifier(let raw):
            let name = raw.lowercased()
            if Functions.names.contains(name) {
                guard peek == .leftParen else { throw peek == nil ? .incomplete : .functionNeedsParens(name) }
                index += 1
                var args: [Expr] = []
                if peek == .rightParen {
                    index += 1
                } else {
                    args.append(try bitOr())
                    while peek == .separator {
                        index += 1
                        args.append(try bitOr())
                    }
                    try closeParen()
                }
                return .call(name, args)
            }
            if Constants.isKnown(name) { return .constant(name) }
            if name == "mod" || name == "xor" { throw .invalidSyntax }
            throw .unknownName(raw)
        default:
            throw .invalidSyntax
        }
    }

    /// Missing closing parentheses at the end are implied: "sqrt(2" works while typing.
    private mutating func closeParen() throws(CalcError) {
        guard let token = advance() else { return }
        guard token == .rightParen else { throw .invalidSyntax }
    }
}

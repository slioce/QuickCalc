import Foundation

struct Evaluator {
    let ans: Double?

    func evaluate(_ expr: Expr) throws(CalcError) -> Double {
        switch expr {
        case .number(let value):
            return value
        case .constant(let name):
            if name == "ans" {
                guard let ans else { throw .noPreviousResult }
                return ans
            }
            return Constants.values[name]!
        case .negate(let operand):
            return -(try evaluate(operand))
        case .bitNot(let operand):
            return Double(~(try Integers.exact(evaluate(operand))))
        case .percent(let operand):
            return try evaluate(operand) / 100
        case .factorial(let operand):
            return try factorial(evaluate(operand))
        case .degrees(let operand):
            return try evaluate(operand) * .pi / 180
        case .call(let name, let args):
            var values: [Double] = []
            for arg in args { values.append(try evaluate(arg)) }
            return try Functions.call(name, values)
        case .binary(let op, let lhs, let rhs):
            return try binary(op, lhs, rhs)
        }
    }

    private func binary(_ op: BinaryOperator, _ lhs: Expr, _ rhs: Expr) throws(CalcError) -> Double {
        let a = try evaluate(lhs)

        // Calculator-style percentages: "200 + 10%" is 200 plus 10% of 200.
        if op == .add || op == .subtract, case .percent(let rate) = rhs {
            let delta = a * (try evaluate(rate)) / 100
            return cancelled(op == .add ? a + delta : a - delta, a, delta)
        }

        let b = try evaluate(rhs)
        switch op {
        case .add: return cancelled(a + b, a, b)
        case .subtract: return cancelled(a - b, a, b)
        case .multiply: return a * b
        case .divide:
            guard b != 0 else { throw .divisionByZero }
            return a / b
        case .modulo:
            guard b != 0 else { throw .divisionByZero }
            return a - b * (a / b).rounded(.down)
        case .power: return pow(a, b)
        case .bitAnd: return Double(try Integers.exact(a) & Integers.exact(b))
        case .bitOr: return Double(try Integers.exact(a) | Integers.exact(b))
        case .bitXor: return Double(try Integers.exact(a) ^ Integers.exact(b))
        case .shiftLeft: return Double(try Integers.exact(a) << shiftAmount(b))
        case .shiftRight: return Double(try Integers.exact(a) >> shiftAmount(b))
        }
    }

    /// Drops floating-point noise left by cancellation, so 0,1+0,2-0,3 is 0.
    private func cancelled(_ result: Double, _ a: Double, _ b: Double) -> Double {
        abs(result) <= max(abs(a), abs(b)) * 4 * .ulpOfOne ? 0 : result
    }

    private func shiftAmount(_ value: Double) throws(CalcError) -> Int64 {
        let amount = try Integers.exact(value)
        guard (0...63).contains(amount) else { throw .shiftOutOfRange }
        return amount
    }

    private func factorial(_ value: Double) throws(CalcError) -> Double {
        let n = try Integers.exact(value)
        guard n >= 0 else { throw .undefined }
        guard n <= 170 else { throw .overflow }
        var result = 1.0
        for k in stride(from: 2, through: n, by: 1) { result *= Double(k) }
        return result
    }
}

enum Integers {
    static func exact(_ value: Double) throws(CalcError) -> Int64 {
        guard !value.isNaN else { throw .undefined }
        guard value.isInfinite || value.rounded() == value else { throw .integerRequired }
        guard let n = Int64(exactly: value) else { throw .integerTooLarge }
        return n
    }
}

enum Constants {
    static let values: [String: Double] = [
        "pi": .pi, "π": .pi,
        "tau": 2 * .pi, "τ": 2 * .pi,
        "e": M_E,
    ]

    static func isKnown(_ name: String) -> Bool {
        name == "ans" || values[name] != nil
    }
}

enum Functions {
    static let names: Set<String> = [
        "sqrt", "cbrt", "abs",
        "sin", "cos", "tan", "asin", "acos", "atan", "sinh", "cosh", "tanh",
        "ln", "log", "log2", "exp",
        "floor", "ceil", "round", "min", "max",
    ]

    static func arity(of name: String) -> Arity {
        switch name {
        case "min", "max": .atLeastTwo
        case "log", "round": .oneOrTwo
        default: .one
        }
    }

    static func call(_ name: String, _ args: [Double]) throws(CalcError) -> Double {
        switch (name, args.count) {
        case ("sqrt", 1): return args[0].squareRoot()
        case ("cbrt", 1): return cbrt(args[0])
        case ("abs", 1): return abs(args[0])
        case ("sin", 1): return trig(sin, args[0])
        case ("cos", 1): return trig(cos, args[0])
        case ("tan", 1): return trig(tan, args[0])
        case ("asin", 1): return asin(args[0])
        case ("acos", 1): return acos(args[0])
        case ("atan", 1): return atan(args[0])
        case ("sinh", 1): return sinh(args[0])
        case ("cosh", 1): return cosh(args[0])
        case ("tanh", 1): return tanh(args[0])
        case ("ln", 1): return log(args[0])
        case ("log", 1): return log10(args[0])
        case ("log", 2): return log(args[0]) / log(args[1])
        case ("log2", 1): return log2(args[0])
        case ("exp", 1): return exp(args[0])
        case ("floor", 1): return args[0].rounded(.down)
        case ("ceil", 1): return args[0].rounded(.up)
        case ("round", 1): return args[0].rounded()
        case ("round", 2):
            let scale = pow(10, Double(try Integers.exact(args[1])))
            return (args[0] * scale).rounded() / scale
        case ("min", 2...): return args.min()!
        case ("max", 2...): return args.max()!
        default: throw .wrongArgumentCount(function: name, expected: arity(of: name))
        }
    }

    /// sin(pi) is 1.2e-16 in floating point; show it as 0.
    private static func trig(_ f: (Double) -> Double, _ x: Double) -> Double {
        let result = f(x)
        return abs(result) < abs(x) * 1e-15 ? 0 : result
    }
}

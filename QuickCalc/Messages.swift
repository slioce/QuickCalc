import Foundation
import QuickCalcCore

/// Looks up a key known only at runtime, without treating "%" as a format specifier.
func localized(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: nil, table: nil)
}

extension CalcError {
    /// Short message shown in place of the result.
    var message: String {
        switch self {
        case .empty: ""
        case .incomplete: String(localized: "Incomplete expression")
        case .invalidSyntax: String(localized: "Invalid expression")
        case .invalidNumber: String(localized: "Invalid number")
        case .invalidCharacter(let character): String(localized: "Invalid character: \(character)")
        case .unknownName(let name): String(localized: "Unknown name: \(name)")
        case .functionNeedsParens(let name): String(localized: "Use \(name)(…)")
        case .wrongArgumentCount(let name, .one): String(localized: "\(name) takes 1 argument")
        case .wrongArgumentCount(let name, .oneOrTwo): String(localized: "\(name) takes 1 or 2 arguments (separate with ;)")
        case .wrongArgumentCount(let name, .atLeastTwo): String(localized: "\(name) takes at least 2 arguments (separate with ;)")
        case .useModForRemainder: String(localized: "Use mod for the remainder")
        case .divisionByZero: String(localized: "Division by zero")
        case .integerRequired: String(localized: "Integer required")
        case .integerTooLarge: String(localized: "Integer too large")
        case .shiftOutOfRange: String(localized: "Shift must be between 0 and 63")
        case .undefined: String(localized: "Undefined result")
        case .overflow: String(localized: "Number too large")
        case .noPreviousResult: String(localized: "No previous result")
        case .unknownUnit(let unit): String(localized: "Unknown unit: \(unit)")
        case .incompatibleUnits(let from, let to): String(localized: "Incompatible units: \(from) → \(to)")
        case .missingSourceUnit: String(localized: "Give the starting unit (e.g. 5 km in m)")
        case .exchangeRatesUnavailable: String(localized: "Exchange rates not downloaded yet: needs internet")
        case .noExchangeRate(let code): String(localized: "No exchange rate for \(code)")
        }
    }
}

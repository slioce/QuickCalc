/// Why an expression has no result. The app turns these into localized messages.
public enum CalcError: Error, Equatable, Sendable {
    case empty
    case incomplete
    case invalidSyntax
    case invalidNumber
    case invalidCharacter(String)
    case unknownName(String)
    case functionNeedsParens(String)
    case wrongArgumentCount(function: String, expected: Arity)
    /// "10 % 3": `%` is a percentage here, the remainder is `mod`.
    case useModForRemainder
    case divisionByZero
    case integerRequired
    case integerTooLarge
    case shiftOutOfRange
    case undefined
    case overflow
    case noPreviousResult
    case unknownUnit(String)
    case incompatibleUnits(String, String)
    case missingSourceUnit
    case exchangeRatesUnavailable
    case noExchangeRate(String)
}

/// How many arguments a function takes.
public enum Arity: Sendable {
    case one, oneOrTwo, atLeastTwo
}

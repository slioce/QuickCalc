import Foundation

/// How numbers are written: the decimal separator of results, and how a lone "1,234" is read.
/// Input accepts both separators either way ("2,5" and "2.5").
public enum DecimalMark: Sendable, CaseIterable {
    /// Results like 2,5; "1,234" is one point two three four.
    case comma
    /// Results like 2.5; "1,234" is one thousand two hundred thirty-four.
    case point

    /// The convention of the user's region.
    public static var current: DecimalMark {
        Locale.current.decimalSeparator == "," ? .comma : .point
    }

    var separator: String {
        switch self {
        case .comma: ","
        case .point: "."
        }
    }
}

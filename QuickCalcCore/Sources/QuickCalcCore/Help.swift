/// One line of the in-app guide. Titles and details are English and double as localization keys.
public struct HelpItem: Sendable {
    public enum Kind: Sendable {
        /// An expression the user can try.
        case example
        /// A key or shortcut.
        case shortcut
        /// A named list, e.g. all length units.
        case list
        /// A plain fact, e.g. the version.
        case info
    }

    public let kind: Kind
    public let label: String
    public let detail: String

    public init(kind: Kind, label: String, detail: String) {
        self.kind = kind
        self.label = label
        self.detail = detail
    }

    static func example(_ expression: String, _ detail: String) -> HelpItem {
        HelpItem(kind: .example, label: expression, detail: detail)
    }

    static func list(_ title: String, _ names: [String]) -> HelpItem {
        HelpItem(kind: .list, label: title, detail: names.joined(separator: " "))
    }
}

public struct HelpSection: Sendable {
    public let title: String
    public let items: [HelpItem]

    public init(title: String, items: [HelpItem]) {
        self.title = title
        self.items = items
    }
}

/// What the calculator understands. Examples follow the decimal mark; the tests try every one.
public enum Help {
    public static func sections(for mark: DecimalMark) -> [HelpSection] {
        let d = mark.separator
        return [
            HelpSection(title: "Basics", items: [
                .example("1250*1\(d)22", "+ − * / (also × ÷)"),
                .example("2,5 + 1.5", "comma or point as decimal"),
                .example("2^10", "power (also **)"),
                .example("(2+3)*4", "parentheses"),
                .example("7 mod 3", "remainder"),
                .example("5!", "factorial"),
                .example("√16 + 3²", "root, square, cube ³"),
                .example("2pi", "implicit multiplication"),
                .example("1\(d)5e3", "scientific notation"),
            ]),
            HelpSection(title: "Percentages and previous result", items: [
                .example("200+10%", "adds 10%"),
                .example("200-15%", "takes off 15%"),
                .example("80*5%", "5% of 80"),
                .example("+22%", "continues from the last result"),
                .example("ans*2", "ans = last result"),
            ]),
            HelpSection(title: "Functions", items: [
                .example("sqrt(2)", "square root (also cbrt)"),
                .example("sin(30°)", "trigonometry, ° for degrees"),
                .example("atan(1)", "asin acos atan sinh cosh tanh"),
                .example("log(1000)", "base-10 logarithm"),
                .example("log(8; 2)", "logarithm in any base"),
                .example("ln(e)", "natural (also log2, exp)"),
                .example("round(3\(d)14159; 2)", "round (floor, ceil, abs)"),
                .example("max(2; 7; 3)", "min and max, separate with ;"),
                .example("tau/2", "constants pi π and tau"),
            ]),
            HelpSection(title: "Programmer", items: [
                .example("0xFF + 0b1010", "hex and binary (0o octal)"),
                .example("255 in hex", "to hex, bin, oct, dec"),
                .example("6 & 3", "bitwise AND (| OR, xor)"),
                .example("~0", "bitwise NOT"),
                .example("1 << 4", "shift (also >>)"),
            ]),
            HelpSection(title: "Units", items: [
                .example("5 km in mi", "convert with in or to"),
                .example("30°C in F", "temperature"),
                .example("1 m3 in l", "volume (m3 or m³)"),
                .example("100 km/h in mph", "speed"),
                .example("1 GiB in MB", "data"),
                .example("100 CV in kW", "power"),
            ] + unitLists),
            HelpSection(title: "Currencies", items: [
                .example("100 USD in EUR", "today's ECB rate"),
                .example("$100 in €", "also with € $ £ ¥"),
                .example("50 dollars to GBP", "euros, dollars, sterling…"),
                .list("Codes", Currencies.codes),
            ]),
        ]
    }

    private static let dimensions: [(UnitDefinition.Dimension, String)] = [
        (.length, "Length"), (.mass, "Mass"), (.time, "Time"), (.temperature, "Temperature"),
        (.volume, "Volume"), (.area, "Area"), (.speed, "Speed"), (.data, "Data"),
        (.energy, "Energy"), (.pressure, "Pressure"), (.power, "Power"),
    ]

    private static var unitLists: [HelpItem] {
        dimensions.map { dimension, title in
            .list(title, Units.definitions.filter { $0.dimension == dimension }.map(\.symbol))
        }
    }
}

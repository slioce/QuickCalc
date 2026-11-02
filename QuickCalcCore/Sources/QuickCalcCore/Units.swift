struct UnitDefinition: Sendable {
    enum Dimension: Sendable {
        case length, mass, time, temperature, volume, area, speed, data, energy, pressure, power, currency
    }

    let names: [String]
    let symbol: String
    let dimension: Dimension
    /// value in the base unit = value × factor + offset (offset only for temperatures)
    let factor: Double
    let offset: Double

    init(_ names: [String], _ dimension: Dimension, _ factor: Double, offset: Double = 0) {
        self.names = names
        self.symbol = names[0]
        self.dimension = dimension
        self.factor = factor
        self.offset = offset
    }

    /// False for a currency whose exchange rate is missing.
    var isAvailable: Bool { !factor.isNaN }

    func toBase(_ value: Double) -> Double { value * factor + offset }
    func fromBase(_ value: Double) -> Double { (value - offset) / factor }
}

enum Units {
    // Base units: m, kg, s, K, l, m², m/s, byte, J, Pa, W.
    static let definitions: [UnitDefinition] = [
        .init(["nm"], .length, 1e-9),
        .init(["µm", "um"], .length, 1e-6),
        .init(["mm"], .length, 0.001),
        .init(["cm"], .length, 0.01),
        .init(["dm"], .length, 0.1),
        .init(["m"], .length, 1),
        .init(["km"], .length, 1000),
        .init(["in", "inch"], .length, 0.0254),
        .init(["ft", "feet"], .length, 0.3048),
        .init(["yd"], .length, 0.9144),
        .init(["mi"], .length, 1609.344),
        .init(["nmi"], .length, 1852),

        .init(["mg"], .mass, 1e-6),
        .init(["g"], .mass, 0.001),
        .init(["kg"], .mass, 1),
        .init(["q"], .mass, 100),
        .init(["t"], .mass, 1000),
        .init(["oz"], .mass, 0.028349523125),
        .init(["lb", "lbs"], .mass, 0.45359237),

        .init(["ms"], .time, 0.001),
        .init(["s", "sec"], .time, 1),
        .init(["min"], .time, 60),
        .init(["h"], .time, 3600),
        .init(["d"], .time, 86400),
        .init(["wk"], .time, 604_800),
        .init(["yr", "y"], .time, 31_557_600),

        .init(["K"], .temperature, 1),
        .init(["°C", "C"], .temperature, 1, offset: 273.15),
        .init(["°F", "F"], .temperature, 5.0 / 9, offset: 273.15 - 32 * 5.0 / 9),

        .init(["mm³", "mm3"], .volume, 1e-6),
        .init(["ml"], .volume, 0.001),
        .init(["cm³", "cm3", "cc"], .volume, 0.001),
        .init(["cl"], .volume, 0.01),
        .init(["dl"], .volume, 0.1),
        .init(["l", "L"], .volume, 1),
        .init(["dm³", "dm3"], .volume, 1),
        .init(["hl"], .volume, 100),
        .init(["m³", "m3"], .volume, 1000),
        .init(["tsp"], .volume, 0.00492892159375),
        .init(["tbsp"], .volume, 0.01478676478125),
        .init(["floz"], .volume, 0.0295735295625),
        .init(["cup"], .volume, 0.2365882365),
        .init(["pt"], .volume, 0.473176473),
        .init(["qt"], .volume, 0.946352946),
        .init(["gal"], .volume, 3.785411784),
        .init(["in³", "in3"], .volume, 0.016387064),
        .init(["ft³", "ft3"], .volume, 28.316846592),

        .init(["mm²", "mm2"], .area, 1e-6),
        .init(["cm²", "cm2"], .area, 1e-4),
        .init(["m²", "m2"], .area, 1),
        .init(["km²", "km2"], .area, 1e6),
        .init(["ha"], .area, 1e4),
        .init(["in²", "in2"], .area, 0.00064516),
        .init(["ft²", "ft2"], .area, 0.09290304),
        .init(["yd²", "yd2"], .area, 0.83612736),
        .init(["acre", "ac"], .area, 4046.8564224),
        .init(["mi²", "mi2"], .area, 2_589_988.110336),

        .init(["m/s"], .speed, 1),
        .init(["km/h", "kmh"], .speed, 1 / 3.6),
        .init(["ft/s"], .speed, 0.3048),
        .init(["mph"], .speed, 0.44704),
        .init(["kn"], .speed, 1852.0 / 3600),

        .init(["bit"], .data, 0.125),
        .init(["kbit"], .data, 125),
        .init(["Mbit"], .data, 125_000),
        .init(["Gbit"], .data, 125_000_000),
        .init(["B"], .data, 1),
        .init(["KB"], .data, 1e3),
        .init(["MB"], .data, 1e6),
        .init(["GB"], .data, 1e9),
        .init(["TB"], .data, 1e12),
        .init(["KiB"], .data, 1024),
        .init(["MiB"], .data, 1_048_576),
        .init(["GiB"], .data, 1_073_741_824),
        .init(["TiB"], .data, 1_099_511_627_776),

        .init(["J"], .energy, 1),
        .init(["kJ"], .energy, 1000),
        .init(["cal"], .energy, 4.184),
        .init(["kcal"], .energy, 4184),
        .init(["Wh"], .energy, 3600),
        .init(["kWh"], .energy, 3.6e6),
        .init(["BTU"], .energy, 1055.05585262),

        .init(["Pa"], .pressure, 1),
        .init(["hPa"], .pressure, 100),
        .init(["mbar"], .pressure, 100),
        .init(["kPa"], .pressure, 1000),
        .init(["bar"], .pressure, 1e5),
        .init(["MPa"], .pressure, 1e6),
        .init(["atm"], .pressure, 101_325),
        .init(["psi"], .pressure, 6894.757293168361),
        .init(["mmHg"], .pressure, 133.322387415),

        .init(["W"], .power, 1),
        .init(["kW"], .power, 1000),
        .init(["MW"], .power, 1e6),
        .init(["CV"], .power, 735.49875),
        .init(["hp"], .power, 745.69987158227022),
    ]
}

/// Name lookup over the fixed units plus the currencies of the given rates.
struct UnitCatalog {
    private let byName: [String: UnitDefinition]
    private let byLowercasedName: [String: UnitDefinition]
    /// Longest first, so "km/h" wins over "h" and "°C" over "C".
    private let namesByLength: [String]

    init(rates: CurrencyRates?) {
        let definitions = Units.definitions + Currencies.definitions(rates: rates)
        byName = Dictionary(
            definitions.flatMap { unit in unit.names.map { ($0, unit) } },
            uniquingKeysWith: { first, _ in first }
        )
        byLowercasedName = Dictionary(
            byName.map { ($0.key.lowercased(), $0.value) },
            uniquingKeysWith: { first, _ in first }
        )
        namesByLength = byName.keys.sorted { $0.count > $1.count }
    }

    /// Exact spelling first, then case-insensitive ("KM" → km).
    func lookup(_ name: String) -> UnitDefinition? {
        byName[name] ?? byLowercasedName[name.lowercased()]
    }

    /// Splits "5 km" into ("5 ", km). The unit must not be glued to a preceding letter,
    /// so "furlong" is not read as "furlon" + "g".
    func splitTrailingUnit(_ text: String) -> (amount: String, unit: UnitDefinition)? {
        let lowercased = text.lowercased()
        for caseSensitive in [true, false] {
            for name in namesByLength {
                let matches = caseSensitive ? text.hasSuffix(name) : lowercased.hasSuffix(name.lowercased())
                guard matches else { continue }
                let amount = text.dropLast(name.count)
                if let before = amount.last, before.isLetter { continue }
                return (String(amount), byName[name]!)
            }
        }
        return nil
    }

    /// Currencies may also come first: "$100", "€ 50", "USD 20".
    func splitLeadingCurrency(_ text: String) -> (amount: String, unit: UnitDefinition)? {
        let lowercased = text.lowercased()
        for caseSensitive in [true, false] {
            for name in namesByLength where byName[name]!.dimension == .currency {
                let matches = caseSensitive ? text.hasPrefix(name) : lowercased.hasPrefix(name.lowercased())
                guard matches else { continue }
                let amount = text.dropFirst(name.count)
                if let after = amount.first, after.isLetter { continue }
                return (String(amount), byName[name]!)
            }
        }
        return nil
    }
}

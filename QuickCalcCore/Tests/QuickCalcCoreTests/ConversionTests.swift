import Testing
@testable import QuickCalcCore

struct UnitTests {
    @Test(arguments: [
        ("5 km in mi", "3,10685596119 mi"),
        ("5 KM in MI", "3,10685596119 mi"),
        ("30°C in F", "86 °F"),
        ("30 C to °F", "86 °F"),
        ("0 K in C", "-273,15 °C"),
        ("5 in in cm", "12,7 cm"),
        ("1 GiB in MB", "1_073,741824 MB"),
        ("8 bit in B", "1 B"),
        ("100 km/h in mph", "62,1371192237 mph"),
        ("10 m/s a kmh", "36 km/h"),
        ("5 km2 in m2", "5_000_000 m²"),
        ("1 ha in m²", "10_000 m²"),
        ("(3+2) kg in lb", "11,0231131092 lb"),
        ("1 kWh a kJ", "3_600 kJ"),
        ("2 h in min", "120 min"),
        ("1,5 l in ml", "1_500 ml"),
        ("1e3m in km", "1 km"),
        ("km in m", "1_000 m"),
        ("1 m3 in l", "1_000 l"),
        ("1 m³ in l", "1_000 l"),
        ("1 l in m3", "0,001 m³"),
        ("500 cm3 in l", "0,5 l"),
        ("2 l in cm³", "2_000 cm³"),
        ("250 cc in ml", "250 ml"),
        ("1 ft3 in l", "28,316846592 l"),
        ("1 hl in l", "100 l"),
        ("1 cup in ml", "236,5882365 ml"),
        ("1 m2 in cm2", "10_000 cm²"),
        ("1 mi2 in km2", "2,58998811034 km²"),
        ("1 atm in bar", "1,01325 bar"),
        ("30 psi in bar", "2,06842718795 bar"),
        ("1013 hPa in atm", "0,999753269183 atm"),
        ("100 CV in kW", "73,549875 kW"),
        ("1 hp in W", "745,699871582 W"),
        ("100 Mbit in MB", "12,5 MB"),
        ("2 q in kg", "200 kg"),
        ("1 yr in d", "365,25 d"),
        ("1000 nm in µm", "1 µm"),
    ])
    func converts(input: String, expected: String) throws {
        #expect(try display(input) == grouped(expected))
    }
}

struct CurrencyTests {
    @Test(arguments: [
        ("100 EUR in USD", "108,00 USD"),
        ("100 USD in EUR", "92,59 EUR"),
        ("100 usd a gbp", "77,78 GBP"),
        ("$100 in €", "92,59 EUR"),
        ("50€ in $", "54,00 USD"),
        ("€ 50 to USD", "54,00 USD"),
        ("1000 JPY in EUR", "6,25 EUR"),
        ("1 JPY in GBP", "0,00525 GBP"),
        ("(10+5) EUR in USD", "16,20 USD"),
        ("1234567 euro in dollari", "1_333_332,36 USD"),
    ])
    func converts(input: String, expected: String) throws {
        #expect(try display(input, rates: sampleRates) == grouped(expected))
    }

    @Test func resultCarriesRatesDateAndCents() throws {
        let result = try Calculator.evaluate("100 USD in EUR", rates: sampleRates, decimalMark: .comma)
        #expect(result.ratesDate == "2026-10-30")
        #expect(result.clipboard == "92,59")
        #expect(result.value == 92.59)
        #expect(try Calculator.evaluate("5 km in mi").ratesDate == nil)
    }

    @Test func errors() {
        #expect(throws: CalcError.noExchangeRate("IDR")) { try Calculator.evaluate("1 EUR in IDR", rates: sampleRates) }
        #expect(throws: CalcError.exchangeRatesUnavailable) { try Calculator.evaluate("100 USD in EUR") }
        #expect(throws: CalcError.incompatibleUnits("USD", "kg")) { try Calculator.evaluate("100 USD in kg", rates: sampleRates) }
    }

    @Test func parsesECBFeed() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
            <gesmes:subject>Reference rates</gesmes:subject>
            <Cube>
                <Cube time='2026-10-30'>
                    <Cube currency='USD' rate='1.0862'/>
                    <Cube currency='JPY' rate='165.23'/>
                    <Cube currency='GBP' rate='0.83915'/>
                </Cube>
            </Cube>
        </gesmes:Envelope>
        """
        let rates = try #require(CurrencyRates.parseECB(xml))
        #expect(rates.date == "2026-10-30")
        #expect(rates.perEuro == ["EUR": 1, "USD": 1.0862, "JPY": 165.23, "GBP": 0.83915])
        #expect(CurrencyRates.parseECB("<html>error</html>") == nil)
    }
}

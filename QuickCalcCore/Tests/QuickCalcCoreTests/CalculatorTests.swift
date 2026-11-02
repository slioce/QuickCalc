import Testing
@testable import QuickCalcCore

struct ArithmeticTests {
    @Test(arguments: [
        ("1+2", "3"),
        ("2+3*4", "14"),
        ("(2+3)*4", "20"),
        ("10/4", "2,5"),
        ("-2^2", "-4"),
        ("2^3^2", "512"),
        ("2^-1", "0,5"),
        ("2**10", "1_024"),
        ("7 mod 3", "1"),
        ("-7 mod 3", "2"),
        ("7,5 mod 2", "1,5"),
        ("5!", "120"),
        ("2pi", "6,28318530718"),
        ("3(4+1)", "15"),
        ("2 sqrt(9)", "6"),
        ("√16", "4"),
        ("√(9+7)", "4"),
        ("3²", "9"),
        ("2³", "8"),
        ("1250*1,22", "1_525"),
        ("0,1+0,2", "0,3"),
        ("0,1+0,2-0,3", "0"),
        ("1/3", "0,333333333333"),
        ("2×3÷4", "1,5"),
        ("−5+2", "-3"),
        ("sqrt(16", "4"),
        ("(1+2", "3"),
        ("1e3", "1_000"),
        ("2,5e-4", "0,00025"),
        ("1e20", "1e20"),
        ("-1,5e-10", "-1,5e-10"),
        ("123456789*1000", "123_456_789_000"),
        ("1234567,89", "1_234_567,89"),
    ])
    func evaluates(input: String, expected: String) throws {
        #expect(try display(input) == grouped(expected))
    }

    @Test(arguments: [
        ("200+10%", "220"),
        ("200-15%", "170"),
        ("80*5%", "4"),
        ("25%", "0,25"),
        ("1000+22%", "1_220"),
    ])
    func percentages(input: String, expected: String) throws {
        #expect(try display(input) == grouped(expected))
    }

    @Test(arguments: [
        ("1.234,5+1", "1_235,5"),
        ("1,234.5+1", "1_235,5"),
        ("1.000.000/1000", "1_000"),
        ("1_525+0", "1_525"),
        ("2.5+2,5", "5"),
        ("1,234 + 1", "2,234"),
    ])
    func decimalSeparators(input: String, expected: String) throws {
        #expect(try display(grouped(input)) == grouped(expected))
    }

    @Test func clipboardHasNoGrouping() throws {
        #expect(try Calculator.evaluate("1234567,89", decimalMark: .comma).clipboard == "1234567,89")
        #expect(try Calculator.evaluate("1250*1,22", decimalMark: .comma).clipboard == "1525")
        #expect(try Calculator.evaluate("5 km in mi", decimalMark: .comma).clipboard == "3,10685596119")
    }

    @Test func valueIsUnrounded() throws {
        #expect(try Calculator.evaluate("1/4").value == 0.25)
        #expect(try Calculator.evaluate("2 km in m").value == 2000)
    }

    @Test func chainingWithAns() throws {
        #expect(try display("+22%", ans: 1250) == grouped("1_525"))
        #expect(try display("*2", ans: 21) == "42")
        #expect(try display("/4", ans: 10) == "2,5")
        #expect(try display("ans/2", ans: 10) == "5")
        #expect(try display("-5", ans: 10) == "-5")
    }
}

struct DecimalPointTests {
    @Test(arguments: [
        ("1250*1.22", "1_525"),
        ("10/4", "2.5"),
        ("2,5 + 1.5", "4"),
        ("1,234 + 1", "1_235"),
        ("1,234.5 + 1", "1_235.5"),
        ("1.234,5 + 1", "1_235.5"),
        ("1_525.5 + 0", "1_525.5"),
        ("1/3", "0.333333333333"),
        ("-1.5e-10", "-1.5e-10"),
        ("5 km in mi", "3.10685596119 mi"),
        ("2^40 in dec", "1_099_511_627_776"),
        ("100 USD in EUR", "92.59 EUR"),
        ("50 dollars to euros", "46.30 EUR"),
        ("100 sterling in EUR", "119.05 EUR"),
    ])
    func evaluates(input: String, expected: String) throws {
        #expect(try display(grouped(input), rates: sampleRates, mark: .point) == grouped(expected))
    }

    @Test func clipboardUsesPoint() throws {
        #expect(try Calculator.evaluate("1234567.891*1", decimalMark: .point).clipboard == "1234567.891")
    }
}

struct FunctionTests {
    @Test(arguments: [
        ("max(2; 7)", "7"),
        ("max(2, 7)", "7"),
        ("min(3; 1; 2)", "1"),
        ("sin(30°)", "0,5"),
        ("cos(pi)", "-1"),
        ("sin(pi)", "0"),
        ("cos(90°)", "0"),
        ("tan(45°)", "1"),
        ("asin(1)", "1,57079632679"),
        ("log(1000)", "3"),
        ("log(8; 2)", "3"),
        ("log2(1024)", "10"),
        ("ln(e)", "1"),
        ("exp(0)", "1"),
        ("round(3,14159; 2)", "3,14"),
        ("round(2,5)", "3"),
        ("abs(-3)", "3"),
        ("floor(2,7)", "2"),
        ("ceil(2,1)", "3"),
        ("cbrt(27)", "3"),
        ("π", "3,14159265359"),
        ("tau/2", "3,14159265359"),
    ])
    func evaluates(input: String, expected: String) throws {
        #expect(try display(input) == grouped(expected))
    }
}

struct ProgrammerTests {
    @Test(arguments: [
        ("0xFF & 0b1111 in hex", "0xF"),
        ("255 in hex", "0xFF"),
        ("255 to HEX", "0xFF"),
        ("10 in bin", "0b1010"),
        ("8 in oct", "0o10"),
        ("0xFF in dec", "255"),
        ("2^40 in dec", "1_099_511_627_776"),
        ("-1 in hex", "0xFFFFFFFFFFFFFFFF"),
        ("1 << 4", "16"),
        ("256 >> 2", "64"),
        ("6 | 3", "7"),
        ("6 xor 3", "5"),
        ("~0", "-1"),
        ("0xFFFFFFFFFFFFFFFF", "-1"),
        ("1 << 60 in hex", "0x1000000000000000"),
        ("1 + 2 & 3", "3"),
    ])
    func evaluates(input: String, expected: String) throws {
        #expect(try display(input) == grouped(expected))
    }
}

struct ErrorTests {
    @Test(arguments: [
        ("", CalcError.empty),
        ("   ", .empty),
        ("2+", .incomplete),
        ("max(2;", .incomplete),
        ("1/0", .divisionByZero),
        ("5 mod 0", .divisionByZero),
        ("10 % 3", .useModForRemainder),
        ("10 %(3)", .useModForRemainder),
        ("2,5 & 1", .integerRequired),
        ("2,5!", .integerRequired),
        ("1e30 in hex", .integerTooLarge),
        ("1 << 64", .shiftOutOfRange),
        ("max(2,7)", .wrongArgumentCount(function: "max", expected: .atLeastTwo)),
        ("sqrt(1; 2)", .wrongArgumentCount(function: "sqrt", expected: .one)),
        ("max(1,5,2)", .invalidNumber),
        ("5 in cm", .missingSourceUnit),
        ("2pi in m", .missingSourceUnit),
        ("5 km in kg", .incompatibleUnits("km", "kg")),
        ("5 km in parsec", .unknownUnit("parsec")),
        ("5 furlong in m", .unknownUnit("furlong")),
        ("foo", .unknownName("foo")),
        ("sqrt 9", .functionNeedsParens("sqrt")),
        ("sqrt(-1)", .undefined),
        ("1e308*10", .overflow),
        ("171!", .overflow),
        ("2 3", .invalidSyntax),
        ("1 000", .invalidSyntax),
        ("1 $ 2", .invalidCharacter("$")),
        ("ans", .noPreviousResult),
        ("+5", .noPreviousResult),
    ] as [(String, CalcError)])
    func reports(input: String, expected: CalcError) {
        #expect(error(input) == expected)
    }
}

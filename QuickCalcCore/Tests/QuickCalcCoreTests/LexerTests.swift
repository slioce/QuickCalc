import Testing
@testable import QuickCalcCore

struct LexerTests {
    @Test(arguments: [
        ("2,5", 2.5),
        ("2.5", 2.5),
        (",5", 0.5),
        ("1.234,5", 1234.5),
        ("1,234.5", 1234.5),
        ("1.000.000", 1_000_000),
        ("1,000,000", 1_000_000),
        ("1.000", 1.0),
        ("1\u{202F}525", 1525),
        ("1\u{202F}234\u{202F}567,89", 1_234_567.89),
        ("1e3", 1000),
        ("2,5e-4", 0.00025),
        ("1E+2", 100),
        ("0xFF", 255),
        ("0b1010", 10),
        ("0o17", 15),
        ("0xFFFFFFFFFFFFFFFF", -1),
        ("2,", 2),
    ])
    func number(input: String, expected: Double) throws {
        #expect(try Lexer.tokenize(input) == [.number(expected)])
    }

    @Test(arguments: ["1,5,2", "1.23,5", "1,2.3,4", "1234.567.890", "0x", "0xFFFFFFFFFFFFFFFFF"])
    func invalidNumber(input: String) {
        #expect(throws: CalcError.invalidNumber) { try Lexer.tokenize(input) }
    }

    @Test func separatorRules() throws {
        #expect(try Lexer.tokenize("max(2, 7)") == [.identifier("max"), .leftParen, .number(2), .separator, .number(7), .rightParen])
        #expect(try Lexer.tokenize("max(2;7)") == [.identifier("max"), .leftParen, .number(2), .separator, .number(7), .rightParen])
        #expect(try Lexer.tokenize("max(2,7)") == [.identifier("max"), .leftParen, .number(2.7), .rightParen])
    }

    @Test func operators() throws {
        #expect(try Lexer.tokenize("1 << 2 >> 3 & 4 | ~5") == [
            .number(1), .shiftLeft, .number(2), .shiftRight, .number(3), .bitAnd, .number(4), .bitOr, .bitNot, .number(5),
        ])
        #expect(try Lexer.tokenize("2×3÷4−1**2") == [
            .number(2), .times, .number(3), .divide, .number(4), .minus, .number(1), .power, .number(2),
        ])
        #expect(try Lexer.tokenize("√9 + 3² + 2³ + 30° + 5! + 10%") == [
            .root, .number(9), .plus, .number(3), .squared, .plus, .number(2), .cubed, .plus,
            .number(30), .degree, .plus, .number(5), .factorial, .plus, .number(10), .percent,
        ])
        #expect(try Lexer.tokenize("2pi + log2(8)") == [
            .number(2), .identifier("pi"), .plus, .identifier("log2"), .leftParen, .number(8), .rightParen,
        ])
    }

    @Test func invalidCharacter() {
        #expect(throws: CalcError.invalidCharacter("$")) { try Lexer.tokenize("1 $ 2") }
    }
}

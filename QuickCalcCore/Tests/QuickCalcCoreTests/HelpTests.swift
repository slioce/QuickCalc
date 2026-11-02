import Testing
@testable import QuickCalcCore

struct HelpTests {
    @Test(arguments: DecimalMark.allCases)
    func everyExampleWorks(mark: DecimalMark) throws {
        let examples = Help.sections(for: mark).flatMap(\.items).filter { $0.kind == .example }
        #expect(examples.count > 30)
        for item in examples {
            #expect(throws: Never.self, "\(item.label)") {
                try Calculator.evaluate(item.label, ans: 100, rates: sampleRates, decimalMark: mark)
            }
        }
    }

    @Test func examplesFollowTheDecimalMark() {
        let labels = { (mark: DecimalMark) in Help.sections(for: mark).flatMap(\.items).map(\.label) }
        #expect(labels(.comma).contains("1250*1,22"))
        #expect(labels(.point).contains("1250*1.22"))
    }

    @Test func listsEveryUnit() {
        let lists = Help.sections(for: .point).flatMap(\.items).filter { $0.kind == .list }
        #expect(lists.contains { $0.label == "Volume" && $0.detail.contains("m³") })
        #expect(lists.contains { $0.label == "Codes" && $0.detail.hasPrefix("EUR USD") })
        let listed = Set(lists.flatMap { $0.detail.split(separator: " ").map(String.init) })
        #expect(Units.definitions.allSatisfy { listed.contains($0.symbol) })
    }
}

import Testing
@testable import TimerCore

@Test func defaultTemplateHasSixBlocks() {
    #expect(Block.defaultTemplate.count == 6)
}

@Test func defaultTemplateSumsToFortyFiveMinutes() {
    let totalSeconds = Block.defaultTemplate.reduce(Int64(0)) {
        $0 + $1.baseline.components.seconds
    }
    #expect(totalSeconds == 45 * 60)
}

@Test func onlyDataFlowIsSkippable() {
    #expect(Block.skippableBlockName == "Data Flow")
    #expect(Block.defaultTemplate.contains { $0.name == Block.skippableBlockName })
}

@Test func sessionTargetMatchesBlockSum() {
    #expect(Session.target == Block.defaultTemplate.reduce(.zero) { $0 + $1.baseline })
}

@Test func newSessionStartsNotStartedWithFullTemplate() {
    let session = Session()
    #expect(session.status == .notStarted)
    #expect(session.blocks.count == 6)
    #expect(session.blocks.allSatisfy { $0.outcome == .upcoming })
}

import Testing
@testable import TimerCore

struct DurationFormattingTests {
    @Test func timerFormattedZeroPadsMinutes() {
        #expect(Duration.seconds(252).timerFormatted() == "04:12")
        #expect(Duration.seconds(45).timerFormatted() == "00:45")
    }

    @Test func signedFormattedIsNeverZeroPaddedOnMinutes() {
        #expect(Duration.seconds(45).signedFormatted() == "+0:45")
        #expect(Duration.seconds(-100).signedFormatted() == "-1:40")
        #expect(Duration.seconds(800).signedFormatted() == "+13:20")
    }

    @Test func wholeMinutesLabelMatchesBlueprintCopy() {
        #expect(Duration.seconds(5 * 60).wholeMinutesLabel == "5m")
        #expect(Duration.seconds(15 * 60).wholeMinutesLabel == "15m")
        #expect(Session.target.wholeMinutesLabel == "45m")
    }
}

import XCTest
@testable import ClockCore

final class ClockTests: XCTestCase {
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    func testClockFormatsSelectedZoneRatherThanSystemZone() {
        let instant = date("2026-01-01T00:15:00Z")
        XCTAssertEqual(Clock(id: "Asia/Tokyo").time(at: instant, use24Hour: true), "09:15")
        XCTAssertEqual(Clock(id: "America/Los_Angeles").time(at: instant, use24Hour: false), "4:15 PM")
    }
    func testDSTChangesWithTheViewedDate() {
        let clock = Clock(id: "America/New_York")
        XCTAssertEqual(clock.time(at: date("2026-03-08T06:30:00Z"), use24Hour: true), "01:30")
        XCTAssertEqual(clock.time(at: date("2026-03-08T07:30:00Z"), use24Hour: true), "03:30")
    }
    func testDayDifferenceAcrossYearAndInternationalDateLine() {
        let instant = date("2026-01-01T00:15:00Z")
        XCTAssertEqual(Clock(id: "America/Los_Angeles").dayDifference(at: instant, relativeTo: TimeZone(identifier: "Asia/Tokyo")!), -1)
        XCTAssertEqual(Clock(id: "Pacific/Kiritimati").dayDifference(at: date("2026-01-01T10:15:00Z"), relativeTo: TimeZone(identifier: "Pacific/Pago_Pago")!), 2)
    }
    func testFractionalUTCOffsets() {
        XCTAssertEqual(Clock(id: "Asia/Kathmandu").offset(at: date("2026-01-01T00:00:00Z")), "UTC+5:45")
        XCTAssertEqual(Clock(id: "America/St_Johns").offset(at: date("2026-01-01T00:00:00Z")), "UTC−3:30")
    }
    func testSearchNormalizesCityNamesAndFindsUTC() {
        XCTAssertTrue(Clock.search("new york").contains("America/New_York"))
        XCTAssertTrue(Clock.search("  tokYO  ").contains("Asia/Tokyo"))
        XCTAssertTrue(Clock.search("UTC").contains("UTC"))
        XCTAssertTrue(Clock.search("not-a-real-city-123").isEmpty)
    }
    func testMenuBarKeepsOverflowAccessibleAndIgnoresUnpinnedClocks() {
        let clocks = [Clock(id: "UTC", label: "Hidden")] + (1...20).map {
            Clock(id: "UTC", label: "Team \($0)", pinned: true)
        }
        let title = Clock.menuBarTitle(clocks: clocks, at: date("2026-01-01T00:00:00Z"), use24Hour: true)
        XCTAssertEqual(title, "Team 1 00:00  ·  Team 2 00:00  +18")
        XCTAssertLessThanOrEqual(title.count, 60)
    }

    func testBlankLabelFallsBackToCity() {
        XCTAssertEqual(Clock(id: "America/New_York", label: "  ").name, "New York")
        XCTAssertEqual(Clock(id: "Asia/Tokyo", label: " Team ").name, "Team")
    }
    func testSavedAbbreviationModeChangesMenuBarName() throws {
        let data = Data(#"[{"id":"America/New_York","label":"Office","pinned":true,"menuBarNameMode":"abbreviation","shortName":"NY"}]"#.utf8)
        let clocks = try JSONDecoder().decode([Clock].self, from: data)
        XCTAssertEqual(Clock.menuBarTitle(clocks: clocks, at: date("2026-01-01T00:00:00Z"), use24Hour: true), "EST 19:00")
    }

    func testLegacyClockDecodesWithOriginalMenuBarDefaults() throws {
        let data = Data(#"{"id":"Asia/Hong_Kong","label":"Office","pinned":true}"#.utf8)
        let clock = try JSONDecoder().decode(Clock.self, from: data)
        XCTAssertEqual(clock.menuBarNameMode, .fullName)
        XCTAssertEqual(clock.shortName, "")
        XCTAssertEqual(clock.menuBarName(at: date("2026-01-01T00:00:00Z")), "Office")
    }

    func testCustomShortNameDoesNotChangeFullName() throws {
        var clock = Clock(id: "Asia/Hong_Kong", label: "Office", pinned: true, menuBarNameMode: .custom, shortName: " HK ")
        let instant = date("2026-01-01T00:00:00Z")
        XCTAssertEqual(clock.menuBarName(at: instant), "HK")
        XCTAssertEqual(clock.name, "Office")
        XCTAssertEqual(try JSONDecoder().decode(Clock.self, from: JSONEncoder().encode(clock)), clock)
        clock.shortName = " \n "
        XCTAssertEqual(clock.menuBarName(at: instant), "Office")
        clock.label = ""
        XCTAssertEqual(clock.menuBarName(at: instant), "Hong Kong")
    }

    func testMenuBarAbbreviationTracksDaylightSavingTransition() {
        let clock = Clock(id: "America/New_York", menuBarNameMode: .abbreviation)
        XCTAssertEqual(clock.menuBarName(at: date("2026-03-08T06:30:00Z")), "EST")
        XCTAssertEqual(clock.menuBarName(at: date("2026-03-08T07:30:00Z")), "EDT")
    }

}

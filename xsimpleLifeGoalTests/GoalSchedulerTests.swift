import XCTest
@testable import xsimpleLifeGoal

final class GoalSchedulerTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testDefaultDeadlineIsOneYearAfterStartDate() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let scheduler = GoalScheduler(calendar: calendar)

        let deadline = scheduler.resolveTargetDate(startDate: start, requestedTargetDate: nil)

        XCTAssertEqual(calendar.component(.year, from: deadline), 2027)
        XCTAssertEqual(calendar.component(.month, from: deadline), 5)
        XCTAssertEqual(calendar.component(.day, from: deadline), 29)
    }

    func testUsesRequestedDeadlineWhenProvided() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let requested = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1)))
        let scheduler = GoalScheduler(calendar: calendar)

        XCTAssertEqual(scheduler.resolveTargetDate(startDate: start, requestedTargetDate: requested), requested)
    }

    func testBuildsDailyPlansFromChecklistTemplates() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 31)))
        let scheduler = GoalScheduler(calendar: calendar)

        let plans = scheduler.makeDailyPlans(
            goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            startDate: start,
            targetDate: target,
            templates: ["Review core concept", "Practice for 10 minutes"]
        )

        XCTAssertEqual(plans.count, 3)
        XCTAssertEqual(plans[0].items.map(\.text), ["Review core concept", "Practice for 10 minutes"])
        XCTAssertFalse(plans[0].isRescaled)
    }

    func testRedistributesIncompleteItemsAcrossRemainingDays() throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let scheduler = GoalScheduler(calendar: calendar)
        var plans = scheduler.makeDailyPlans(
            goalID: goalID,
            startDate: start,
            targetDate: target,
            templates: ["Read", "Practice", "Review"]
        )
        plans[0].items[0].isCompleted = true

        let rescaled = scheduler.rescaleAfterMissedDay(plans: plans, missedDate: start, targetDate: target)

        XCTAssertEqual(rescaled[0].items.filter { !$0.isCompleted }.count, 2)
        XCTAssertTrue(rescaled[1].isRescaled)
        XCTAssertTrue(rescaled[2].isRescaled)
        XCTAssertTrue(rescaled[3].isRescaled)
        XCTAssertGreaterThan(rescaled[1].items.count, plans[1].items.count)
    }
}

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

    func testEmptyTemplatesUseFocusedTimeFallback() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let scheduler = GoalScheduler(calendar: calendar)

        let plans = scheduler.makeDailyPlans(
            goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            startDate: start,
            targetDate: start,
            templates: []
        )

        XCTAssertEqual(plans[0].items.map(\.text), ["Spend focused time on this goal"])
    }

    func testBaseDailyPlansTruncateTemplatesToThreeItems() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let scheduler = GoalScheduler(calendar: calendar)

        let plans = scheduler.makeDailyPlans(
            goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            startDate: start,
            targetDate: start,
            templates: ["Read", "Practice", "Review", "Stretch"]
        )

        XCTAssertEqual(plans[0].items.map(\.text), ["Read", "Practice", "Review"])
    }

    func testGeneratedChecklistItemsStartSmallAndIncomplete() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let scheduler = GoalScheduler(calendar: calendar)

        let plans = scheduler.makeDailyPlans(
            goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            startDate: start,
            targetDate: start,
            templates: ["Read", "Practice"]
        )

        XCTAssertEqual(plans[0].items.map(\.estimatedEffort), ["Small", "Small"])
        XCTAssertTrue(plans[0].items.allSatisfy { !$0.isCompleted })
        XCTAssertTrue(plans[0].items.allSatisfy { $0.completedDate == nil })
    }

    func testMakeDailyPlansUsesInjectedIDsDeterministically() throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30)))
        let firstScheduler = GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator())
        let secondScheduler = GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator())

        let firstPlans = firstScheduler.makeDailyPlans(
            goalID: goalID,
            startDate: start,
            targetDate: target,
            templates: ["Read", "Practice"]
        )
        let secondPlans = secondScheduler.makeDailyPlans(
            goalID: goalID,
            startDate: start,
            targetDate: target,
            templates: ["Read", "Practice"]
        )

        XCTAssertEqual(firstPlans, secondPlans)
        XCTAssertEqual(firstPlans.map(\.id), [deterministicID(1), deterministicID(4)])
        XCTAssertEqual(firstPlans[0].items.map(\.id), [deterministicID(2), deterministicID(3)])
    }

    func testTargetDateBeforeStartDateProducesSingleDayPlan() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        let scheduler = GoalScheduler(calendar: calendar)

        let plans = scheduler.makeDailyPlans(
            goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            startDate: start,
            targetDate: target,
            templates: ["Read"]
        )

        XCTAssertEqual(plans.count, 1)
        XCTAssertTrue(calendar.isDate(plans[0].date, inSameDayAs: start))
    }

    func testRedistributesIncompleteItemsAcrossRemainingDaysAndMayExceedBaseCap() throws {
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
        XCTAssertGreaterThan(
            rescaled[1].items.count,
            plans[1].items.count,
            "Rescaling can exceed the base three-item cap to preserve missed work."
        )
    }

    func testRedistributionClearsCompletedDateOnCopiedMissedItems() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30)))
        let scheduler = GoalScheduler(calendar: calendar)
        var plans = scheduler.makeDailyPlans(
            goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            startDate: start,
            targetDate: target,
            templates: ["Read"]
        )
        plans[0].items[0].text = "Missed unique task"
        plans[0].items[0].completedDate = start

        let rescaled = scheduler.rescaleAfterMissedDay(plans: plans, missedDate: start, targetDate: target)
        let redistributed = try XCTUnwrap(rescaled[1].items.first { $0.text.hasSuffix("Missed unique task") })

        XCTAssertEqual(redistributed.text, "[catch-up 2026-05-29] Missed unique task")
        XCTAssertFalse(redistributed.isCompleted)
        XCTAssertNil(redistributed.completedDate)
        XCTAssertNotEqual(redistributed.id, plans[0].items[0].id)
    }

    func testRescaleAfterMissedDayIsIdempotentForSameMissedDate() throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let scheduler = GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator())
        var plans = scheduler.makeDailyPlans(
            goalID: goalID,
            startDate: start,
            targetDate: target,
            templates: ["Read", "Practice", "Review"]
        )
        plans[0].items[0].isCompleted = true

        let firstRescale = scheduler.rescaleAfterMissedDay(plans: plans, missedDate: start, targetDate: target)
        let secondRescale = scheduler.rescaleAfterMissedDay(plans: firstRescale, missedDate: start, targetDate: target)

        XCTAssertEqual(secondRescale, firstRescale)
    }

    func testLaterMissedDayCanRescaleAfterEarlierRescale() throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let may29 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let may30 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let scheduler = GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator())
        var plans = scheduler.makeDailyPlans(
            goalID: goalID,
            startDate: may29,
            targetDate: target,
            templates: ["Read", "Practice", "Review"]
        )
        plans[0].items[0].isCompleted = true

        let rescaledForMay29 = scheduler.rescaleAfterMissedDay(plans: plans, missedDate: may29, targetDate: target)
        let rescaledForMay30 = scheduler.rescaleAfterMissedDay(plans: rescaledForMay29, missedDate: may30, targetDate: target)

        XCTAssertNotEqual(rescaledForMay30, rescaledForMay29)
        XCTAssertGreaterThan(rescaledForMay30[2].items.count, rescaledForMay29[2].items.count)
        XCTAssertTrue(rescaledForMay30[2].items.contains { $0.text.hasPrefix("[catch-up 2026-05-30]") })
    }

    func testGoalProgressFractionReflectsCompletedChecklistItems() throws {
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
        let goal = Goal(
            id: goalID,
            title: "Learn SwiftUI",
            originalDescription: "Build one tiny app",
            createdDate: date,
            targetDate: date,
            status: .active,
            selectedModelID: "local-model",
            dailyPlans: [
                DailyPlan(
                    id: UUID(),
                    goalID: goalID,
                    date: date,
                    items: [
                        ChecklistItem(id: UUID(), text: "Read", estimatedEffort: "Small", isCompleted: true, completedDate: date),
                        ChecklistItem(id: UUID(), text: "Practice", estimatedEffort: "Small", isCompleted: false, completedDate: nil),
                        ChecklistItem(id: UUID(), text: "Review", estimatedEffort: "Small", isCompleted: true, completedDate: date)
                    ],
                    isRescaled: false
                )
            ]
        )

        XCTAssertEqual(goal.progressFraction, 2.0 / 3.0, accuracy: 0.0001)
    }

    private func makeDeterministicIDGenerator() -> () -> UUID {
        var nextID = 1
        return {
            defer { nextID += 1 }
            return self.deterministicID(nextID)
        }
    }

    private func deterministicID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}

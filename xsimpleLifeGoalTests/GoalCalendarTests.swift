import XCTest
@testable import xsimpleLifeGoal

final class GoalCalendarTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testClampedSelectionUsesGoalStartWhenTodayIsBeforeGoalRange() throws {
        let start = try makeDate(year: 2026, month: 6, day: 10)
        let end = try makeDate(year: 2026, month: 6, day: 20)
        let preferred = try makeDate(year: 2026, month: 6, day: 1)
        let goal = makeGoal(createdDate: start, targetDate: end)

        let selected = GoalCalendarHelper.clampedSelection(preferred: preferred, goal: goal, calendar: calendar)

        XCTAssertTrue(calendar.isDate(selected, inSameDayAs: start))
    }

    func testClampedSelectionUsesPreferredDateWhenInsideGoalRange() throws {
        let start = try makeDate(year: 2026, month: 6, day: 10)
        let end = try makeDate(year: 2026, month: 6, day: 20)
        let preferred = try makeDate(year: 2026, month: 6, day: 15)
        let goal = makeGoal(createdDate: start, targetDate: end)

        let selected = GoalCalendarHelper.clampedSelection(preferred: preferred, goal: goal, calendar: calendar)

        XCTAssertTrue(calendar.isDate(selected, inSameDayAs: preferred))
    }

    func testClampedSelectionUsesGoalEndWhenTodayIsAfterGoalRange() throws {
        let start = try makeDate(year: 2026, month: 6, day: 10)
        let end = try makeDate(year: 2026, month: 6, day: 20)
        let preferred = try makeDate(year: 2026, month: 7, day: 1)
        let goal = makeGoal(createdDate: start, targetDate: end)

        let selected = GoalCalendarHelper.clampedSelection(preferred: preferred, goal: goal, calendar: calendar)

        XCTAssertTrue(calendar.isDate(selected, inSameDayAs: end))
    }

    func testMonthGridIncludesLeadingBlanksBeforeFirstDay() throws {
        var fixedCalendar = Calendar(identifier: .gregorian)
        fixedCalendar.firstWeekday = 1
        let start = try makeDate(year: 2026, month: 5, day: 1)
        let end = try makeDate(year: 2026, month: 5, day: 31)
        let goal = makeGoal(createdDate: start, targetDate: end)

        let days = GoalCalendarHelper.monthGrid(containing: start, goal: goal, calendar: fixedCalendar)

        XCTAssertEqual(days.prefix(5).map(\.date), Array(repeating: nil, count: 5))
        XCTAssertTrue(fixedCalendar.isDate(try XCTUnwrap(days[5].date), inSameDayAs: start))
    }

    func testDayCompletionStateIsEmptyWhenPlanHasNoItems() {
        let plan = DailyPlan(id: UUID(), goalID: UUID(), date: Date(), items: [], isRescaled: false)

        XCTAssertEqual(GoalCalendarHelper.completionState(for: plan), .empty)
    }

    func testDayCompletionStateIsNotStartedWhenNoItemsAreComplete() {
        let plan = makePlan(items: [
            makeItem(isCompleted: false),
            makeItem(isCompleted: false)
        ])

        XCTAssertEqual(GoalCalendarHelper.completionState(for: plan), .notStarted)
    }

    func testDayCompletionStateIsPartialWhenSomeItemsAreComplete() {
        let plan = makePlan(items: [
            makeItem(isCompleted: true),
            makeItem(isCompleted: false)
        ])

        XCTAssertEqual(GoalCalendarHelper.completionState(for: plan), .partial)
    }

    func testDayCompletionStateIsCompleteWhenAllItemsAreComplete() {
        let plan = makePlan(items: [
            makeItem(isCompleted: true),
            makeItem(isCompleted: true)
        ])

        XCTAssertEqual(GoalCalendarHelper.completionState(for: plan), .complete)
    }

    func testDayCompletionStateIsRescaledForRescaledPlan() {
        let plan = DailyPlan(id: UUID(), goalID: UUID(), date: Date(), items: [
            makeItem(isCompleted: false)
        ], isRescaled: true)

        XCTAssertEqual(GoalCalendarHelper.completionState(for: plan), .rescaled)
    }

    private func makeGoal(createdDate: Date, targetDate: Date) -> Goal {
        Goal(
            id: UUID(),
            title: "Test goal",
            originalDescription: "Test goal",
            createdDate: createdDate,
            targetDate: targetDate,
            status: .active,
            selectedModelID: ModelManager.defaultModel.id,
            dailyPlans: []
        )
    }

    private func makePlan(items: [ChecklistItem]) -> DailyPlan {
        DailyPlan(id: UUID(), goalID: UUID(), date: Date(), items: items, isRescaled: false)
    }

    private func makeItem(isCompleted: Bool) -> ChecklistItem {
        ChecklistItem(
            id: UUID(),
            text: "Work",
            estimatedEffort: "Small",
            isCompleted: isCompleted,
            completedDate: isCompleted ? Date() : nil
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}

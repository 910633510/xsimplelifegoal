import XCTest
@testable import xsimpleLifeGoal

final class GoalDomainTests: XCTestCase {
    func testDailyPlanOnSelectsPlanMatchingCalendarDayNotFirstPlan() throws {
        let calendar = Calendar(identifier: .gregorian)
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let firstDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29, hour: 9)))
        let secondDayMorning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30, hour: 8)))
        let secondDayEvening = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30, hour: 18)))
        let firstPlan = makePlan(id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!, goalID: goalID, date: firstDay, text: "Day one")
        let secondPlan = makePlan(id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!, goalID: goalID, date: secondDayMorning, text: "Day two")
        let goal = Goal(
            id: goalID,
            title: "Build a habit",
            originalDescription: "Build a habit",
            createdDate: firstDay,
            targetDate: secondDayMorning,
            status: .active,
            selectedModelID: ModelManager.defaultModel.id,
            dailyPlans: [firstPlan, secondPlan]
        )

        let plan = goal.dailyPlan(on: secondDayEvening, calendar: calendar)

        XCTAssertEqual(plan?.id, secondPlan.id)
    }

    private func makePlan(id: UUID, goalID: UUID, date: Date, text: String) -> DailyPlan {
        DailyPlan(
            id: id,
            goalID: goalID,
            date: date,
            items: [
                ChecklistItem(
                    id: UUID(),
                    text: text,
                    estimatedEffort: "15 minutes",
                    isCompleted: false,
                    completedDate: nil
                )
            ],
            isRescaled: false
        )
    }
}

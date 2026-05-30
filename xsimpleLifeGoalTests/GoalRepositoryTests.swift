import XCTest
import SwiftData
@testable import xsimpleLifeGoal

@MainActor
final class GoalRepositoryTests: XCTestCase {
    func testSavesAndLoadsGoalRoundTrip() throws {
        let schema = Schema([StoredGoal.self, StoredDailyPlan.self, StoredChecklistItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let repository = SwiftDataGoalRepository(context: container.mainContext)
        let goal = Goal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            title: "Learn Spanish",
            originalDescription: "learn conversational Spanish",
            createdDate: Date(timeIntervalSince1970: 10),
            targetDate: Date(timeIntervalSince1970: 20),
            status: .active,
            selectedModelID: "qwen3-1.7b-gguf",
            dailyPlans: [
                DailyPlan(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                    goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                    date: Date(timeIntervalSince1970: 10),
                    items: [
                        ChecklistItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, text: "Review", estimatedEffort: "Small", isCompleted: false, completedDate: nil)
                    ],
                    isRescaled: false
                )
            ]
        )

        try repository.save(goal)
        let goals = try repository.fetchGoals()

        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals[0].title, "Learn Spanish")
        XCTAssertEqual(goals[0].dailyPlans[0].items[0].text, "Review")
    }
}

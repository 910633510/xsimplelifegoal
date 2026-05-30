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
                        ChecklistItem(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
                            text: "Review",
                            estimatedEffort: "Small",
                            isCompleted: true,
                            completedDate: Date(timeIntervalSince1970: 15)
                        )
                    ],
                    isRescaled: false
                )
            ]
        )

        try repository.save(goal)
        let goals = try repository.fetchGoals()

        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals[0].title, "Learn Spanish")
        XCTAssertEqual(goals[0].status, .active)
        XCTAssertEqual(goals[0].selectedModelID, "qwen3-1.7b-gguf")
        XCTAssertEqual(goals[0].dailyPlans[0].items[0].text, "Review")
        XCTAssertTrue(goals[0].dailyPlans[0].items[0].isCompleted)
        XCTAssertEqual(goals[0].dailyPlans[0].items[0].completedDate, Date(timeIntervalSince1970: 15))
    }

    func testSavingGoalWithSameIDReplacesExistingGoalAndChildGraph() throws {
        let schema = Schema([StoredGoal.self, StoredDailyPlan.self, StoredChecklistItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let repository = SwiftDataGoalRepository(context: container.mainContext)
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
        let firstGoal = Goal(
            id: goalID,
            title: "First",
            originalDescription: "first description",
            createdDate: Date(timeIntervalSince1970: 20),
            targetDate: Date(timeIntervalSince1970: 30),
            status: .active,
            selectedModelID: "qwen3-1.7b-gguf",
            dailyPlans: [
                DailyPlan(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
                    goalID: goalID,
                    date: Date(timeIntervalSince1970: 20),
                    items: [
                        ChecklistItem(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!,
                            text: "Original item",
                            estimatedEffort: "Small",
                            isCompleted: false,
                            completedDate: nil
                        )
                    ],
                    isRescaled: false
                )
            ]
        )
        let updatedGoal = Goal(
            id: goalID,
            title: "Updated",
            originalDescription: "updated description",
            createdDate: Date(timeIntervalSince1970: 20),
            targetDate: Date(timeIntervalSince1970: 40),
            status: .completed,
            selectedModelID: "qwen3-0.6b-gguf",
            dailyPlans: [
                DailyPlan(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!,
                    goalID: goalID,
                    date: Date(timeIntervalSince1970: 25),
                    items: [
                        ChecklistItem(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000024")!,
                            text: "Updated item",
                            estimatedEffort: "Medium",
                            isCompleted: true,
                            completedDate: Date(timeIntervalSince1970: 35)
                        )
                    ],
                    isRescaled: true
                )
            ]
        )

        try repository.save(firstGoal)
        try repository.save(updatedGoal)
        let goals = try repository.fetchGoals()

        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals[0].title, "Updated")
        XCTAssertEqual(goals[0].status, .completed)
        XCTAssertEqual(goals[0].selectedModelID, "qwen3-0.6b-gguf")
        XCTAssertEqual(goals[0].dailyPlans.count, 1)
        XCTAssertEqual(goals[0].dailyPlans[0].items.map(\.text), ["Updated item"])
    }
}

import XCTest
@testable import xsimpleLifeGoal

@MainActor
final class GoalStoreTests: XCTestCase {
    func testCreatesGoalWithGeneratedPlan() async throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: Calendar(identifier: .gregorian))
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review","Speak"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { Date(timeIntervalSince1970: 0) })

        try await store.createGoal(description: "learn conversational Spanish", targetDate: Date(timeIntervalSince1970: 86_400))

        XCTAssertEqual(store.goals.count, 1)
        XCTAssertEqual(store.goals[0].title, "Learn Spanish")
        XCTAssertEqual(store.goals[0].dailyPlans.count, 2)
    }

    func testTogglesChecklistItemCompletion() async throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: Calendar(identifier: .gregorian))
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { Date(timeIntervalSince1970: 0) })
        try await store.createGoal(description: "learn Spanish", targetDate: Date(timeIntervalSince1970: 0))
        let goalID = store.goals[0].id
        let itemID = store.goals[0].dailyPlans[0].items[0].id

        try store.setChecklistItem(goalID: goalID, itemID: itemID, isCompleted: true)

        XCTAssertTrue(store.goals[0].dailyPlans[0].items[0].isCompleted)
    }
}

private final class InMemoryGoalRepository: GoalRepository {
    var goals: [Goal] = []

    func fetchGoals() throws -> [Goal] {
        goals
    }

    func save(_ goal: Goal) throws {
        goals.removeAll { $0.id == goal.id }
        goals.append(goal)
    }
}

private struct FixtureTextGenerator: TextGenerating {
    let result: String

    func generateText(prompt: String) async throws -> String {
        result
    }
}

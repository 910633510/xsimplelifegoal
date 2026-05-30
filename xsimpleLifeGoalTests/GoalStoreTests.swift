import XCTest
@testable import xsimpleLifeGoal

@MainActor
final class GoalStoreTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

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

    func testCreateGoalPassesDaysAvailableMatchingScheduledPlansToPlanner() async throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: calendar)
        let generator = CapturingTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#)
        let engine = GoalPlanningEngine(generator: generator)
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { Date(timeIntervalSince1970: 0) })

        try await store.createGoal(description: "learn Spanish", targetDate: Date(timeIntervalSince1970: 86_400))

        let capturedPrompt = await generator.capturedPrompt()
        let prompt = try XCTUnwrap(capturedPrompt)
        XCTAssertEqual(store.goals[0].dailyPlans.count, 2)
        XCTAssertTrue(prompt.contains("Days available: 2"))
    }

    func testInitialFetchFailureSetsErrorMessageAndLeavesGoalsEmpty() {
        let repository = InMemoryGoalRepository(fetchError: TestError.fetchFailed)
        let scheduler = GoalScheduler(calendar: Calendar(identifier: .gregorian))
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))

        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine)

        XCTAssertTrue(store.goals.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testSuccessfulCreateClearsInitialFetchErrorMessage() async throws {
        let repository = InMemoryGoalRepository(fetchError: TestError.fetchFailed)
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { Date(timeIntervalSince1970: 0) })
        XCTAssertNotNil(store.errorMessage)
        repository.fetchError = nil

        try await store.createGoal(description: "learn Spanish", targetDate: Date(timeIntervalSince1970: 0))

        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.goals.count, 1)
    }

    func testTogglesChecklistItemCompletion() async throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: Calendar(identifier: .gregorian))
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let completedDate = Date(timeIntervalSince1970: 123)
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { completedDate })
        try await store.createGoal(description: "learn Spanish", targetDate: Date(timeIntervalSince1970: 0))
        let goalID = store.goals[0].id
        let itemID = store.goals[0].dailyPlans[0].items[0].id

        try store.setChecklistItem(goalID: goalID, itemID: itemID, isCompleted: true)

        XCTAssertTrue(store.goals[0].dailyPlans[0].items[0].isCompleted)
        XCTAssertEqual(store.goals[0].dailyPlans[0].items[0].completedDate, completedDate)
        XCTAssertEqual(repository.goals[0].dailyPlans[0].items[0], store.goals[0].dailyPlans[0].items[0])

        try store.setChecklistItem(goalID: goalID, itemID: itemID, isCompleted: false)

        XCTAssertFalse(store.goals[0].dailyPlans[0].items[0].isCompleted)
        XCTAssertNil(store.goals[0].dailyPlans[0].items[0].completedDate)
        XCTAssertEqual(repository.goals[0].dailyPlans[0].items[0], store.goals[0].dailyPlans[0].items[0])
    }

    func testToggleSaveFailureLeavesStoreGoalsUnchanged() throws {
        let goal = makeGoal()
        let repository = InMemoryGoalRepository(goals: [goal])
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { Date(timeIntervalSince1970: 123) })
        repository.saveError = TestError.saveFailed

        XCTAssertThrowsError(try store.setChecklistItem(goalID: goal.id, itemID: goal.dailyPlans[0].items[0].id, isCompleted: true))
        XCTAssertEqual(store.goals[0], goal)
        XCTAssertFalse(store.goals[0].dailyPlans[0].items[0].isCompleted)
        XCTAssertNil(store.goals[0].dailyPlans[0].items[0].completedDate)
    }

    func testSetChecklistItemThrowsGoalNotFoundWhenGoalIsMissing() throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine)

        XCTAssertThrowsError(try store.setChecklistItem(goalID: UUID(), itemID: UUID(), isCompleted: true)) { error in
            XCTAssertEqual(error as? GoalStoreError, .goalNotFound)
        }
    }

    func testSetChecklistItemThrowsChecklistItemNotFoundWhenItemIsMissing() throws {
        let goal = makeGoal()
        let repository = InMemoryGoalRepository(goals: [goal])
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine)

        XCTAssertThrowsError(try store.setChecklistItem(goalID: goal.id, itemID: UUID(), isCompleted: true)) { error in
            XCTAssertEqual(error as? GoalStoreError, .checklistItemNotFound)
        }
    }

    func testRescaleSaveFailureLeavesStoreGoalsUnchanged() throws {
        let goal = makeGoal(targetDate: Date(timeIntervalSince1970: 86_400))
        let repository = InMemoryGoalRepository(goals: [goal])
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine)
        repository.saveError = TestError.saveFailed

        XCTAssertThrowsError(try store.rescaleMissedDay(goalID: goal.id, missedDate: goal.createdDate))
        XCTAssertEqual(store.goals[0].dailyPlans, goal.dailyPlans)
    }

    func testRescaleMissedDayThrowsGoalNotFoundWhenGoalIsMissing() throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine)

        XCTAssertThrowsError(try store.rescaleMissedDay(goalID: UUID(), missedDate: Date(timeIntervalSince1970: 0))) { error in
            XCTAssertEqual(error as? GoalStoreError, .goalNotFound)
        }
    }

    func testRescaleMissedDayPersistsAndRefreshesStoreGoals() throws {
        let goal = makeGoal(targetDate: Date(timeIntervalSince1970: 86_400))
        let repository = InMemoryGoalRepository(goals: [goal])
        repository.afterSave = { saved in
            var updated = saved
            updated.title = "Fetched after save"
            return updated
        }
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine)

        try store.rescaleMissedDay(goalID: goal.id, missedDate: goal.createdDate)

        XCTAssertEqual(store.goals, repository.goals)
        XCTAssertEqual(store.goals[0].title, "Fetched after save")
        XCTAssertTrue(store.goals[0].dailyPlans[1].isRescaled)
        XCTAssertTrue(store.goals[0].dailyPlans[1].items.contains { $0.text.hasPrefix("[catch-up ") })
    }

    private func makeGoal(targetDate: Date = Date(timeIntervalSince1970: 0)) -> Goal {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let start = Date(timeIntervalSince1970: 0)
        return Goal(
            id: goalID,
            title: "Learn Spanish",
            originalDescription: "learn Spanish",
            createdDate: start,
            targetDate: targetDate,
            status: .active,
            selectedModelID: ModelManager.defaultModel.id,
            dailyPlans: GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator()).makeDailyPlans(
                goalID: goalID,
                startDate: start,
                targetDate: targetDate,
                templates: ["Review"]
            )
        )
    }
}

private final class InMemoryGoalRepository: GoalRepository {
    var goals: [Goal]
    var fetchError: Error?
    var saveError: Error?
    var afterSave: ((Goal) -> Goal)?

    init(goals: [Goal] = [], fetchError: Error? = nil, saveError: Error? = nil) {
        self.goals = goals
        self.fetchError = fetchError
        self.saveError = saveError
    }

    func fetchGoals() throws -> [Goal] {
        if let fetchError {
            throw fetchError
        }
        return goals
    }

    func save(_ goal: Goal) throws {
        if let saveError {
            throw saveError
        }
        goals.removeAll { $0.id == goal.id }
        goals.append(afterSave?(goal) ?? goal)
    }
}

private struct FixtureTextGenerator: TextGenerating {
    let result: String

    func generateText(prompt: String) async throws -> String {
        result
    }
}

private actor CapturingTextGenerator: TextGenerating {
    let result: String
    private(set) var prompt: String?

    init(result: String) {
        self.result = result
    }

    func generateText(prompt: String) async throws -> String {
        self.prompt = prompt
        return result
    }

    func capturedPrompt() -> String? {
        prompt
    }
}

private enum TestError: Error {
    case fetchFailed
    case saveFailed
}

private func makeDeterministicIDGenerator() -> () -> UUID {
    var index = 0
    return {
        index += 1
        return UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index))!
    }
}

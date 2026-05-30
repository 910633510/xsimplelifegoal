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

    func testCreateGoalSavesInjectedSelectedModelID() async throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: calendar)
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(
            repository: repository,
            scheduler: scheduler,
            planningEngine: engine,
            selectedModelID: "qwen3-selected-local",
            now: { Date(timeIntervalSince1970: 0) }
        )

        try await store.createGoal(description: "learn Spanish", targetDate: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(store.goals[0].selectedModelID, "qwen3-selected-local")
        XCTAssertEqual(repository.goals[0].selectedModelID, "qwen3-selected-local")
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

    func testCreateGoalRejectsPastTargetDateBeforeGeneratingOrSaving() async throws {
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let yesterday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 28)))
        let repository = InMemoryGoalRepository()
        let generator = CountingTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#)
        let engine = GoalPlanningEngine(generator: generator)
        let store = GoalStore(repository: repository, scheduler: GoalScheduler(calendar: calendar), planningEngine: engine, now: { today })

        do {
            try await store.createGoal(description: "learn Spanish", targetDate: yesterday)
            XCTFail("Expected past target date to be rejected.")
        } catch {
            XCTAssertEqual(error as? GoalStoreError, .targetDateInPast)
        }

        XCTAssertTrue(repository.goals.isEmpty)
        let generateCallCount = await generator.callCount()
        XCTAssertEqual(generateCallCount, 0)
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

    func testReconcileMissedWorkRedistributesIncompletePriorDayItemsToFuturePlans() throws {
        let may29 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let may30 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30)))
        let may31 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 31)))
        let goal = makeGoal(startDate: may29, targetDate: may31, templates: ["Review", "Speak"])
        let repository = InMemoryGoalRepository(goals: [goal])
        let scheduler = GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator())
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { may30 })

        try store.reconcileMissedWork()

        let updatedGoal = try XCTUnwrap(store.goals.first)
        let todayPlan = try XCTUnwrap(updatedGoal.dailyPlan(on: may30, calendar: calendar))
        let finalPlan = try XCTUnwrap(updatedGoal.dailyPlan(on: may31, calendar: calendar))
        XCTAssertTrue(todayPlan.items.contains { $0.text.hasPrefix("[catch-up 2026-05-29]") })
        XCTAssertTrue(finalPlan.items.contains { $0.text.hasPrefix("[catch-up 2026-05-29]") })
    }

    func testReconcileMissedWorkIsIdempotentForAlreadyRescaledPriorDays() throws {
        let may30 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 30)))
        let may31 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 31)))
        let may29 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let goal = makeGoal(startDate: may29, targetDate: may31, templates: ["Review", "Speak"])
        let repository = InMemoryGoalRepository(goals: [goal])
        let scheduler = GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator())
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { may30 })

        try store.reconcileMissedWork()
        let afterFirstReconcile = store.goals
        try store.reconcileMissedWork()

        XCTAssertEqual(store.goals, afterFirstReconcile)
    }

    private func makeGoal(
        startDate: Date = Date(timeIntervalSince1970: 0),
        targetDate: Date = Date(timeIntervalSince1970: 0),
        templates: [String] = ["Review"]
    ) -> Goal {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        return Goal(
            id: goalID,
            title: "Learn Spanish",
            originalDescription: "learn Spanish",
            createdDate: startDate,
            targetDate: targetDate,
            status: .active,
            selectedModelID: ModelManager.defaultModel.id,
            dailyPlans: GoalScheduler(calendar: calendar, makeID: makeDeterministicIDGenerator()).makeDailyPlans(
                goalID: goalID,
                startDate: startDate,
                targetDate: targetDate,
                templates: templates
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

private actor CountingTextGenerator: TextGenerating {
    let result: String
    private var calls = 0

    init(result: String) {
        self.result = result
    }

    func generateText(prompt: String) async throws -> String {
        calls += 1
        return result
    }

    func callCount() -> Int {
        calls
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

import Foundation
import Observation

@MainActor
@Observable
final class GoalStore {
    private let repository: GoalRepository
    private let scheduler: GoalScheduler
    private let planningEngine: GoalPlanningEngine
    private let now: () -> Date

    private(set) var goals: [Goal] = []
    var errorMessage: String?

    init(repository: GoalRepository, scheduler: GoalScheduler, planningEngine: GoalPlanningEngine, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.scheduler = scheduler
        self.planningEngine = planningEngine
        self.now = now
        do {
            self.goals = try repository.fetchGoals()
        } catch {
            self.goals = []
            self.errorMessage = "Failed to load goals: \(error.localizedDescription)"
        }
    }

    func createGoal(description: String, targetDate: Date?) async throws {
        let start = now()
        let resolvedTarget = scheduler.resolveTargetDate(startDate: start, requestedTargetDate: targetDate)
        let days = max(1, Calendar.current.dateComponents([.day], from: start, to: resolvedTarget).day ?? 1)
        let generated = try await planningEngine.generatePlan(description: description, daysAvailable: days)
        let goalID = UUID()
        let plans = scheduler.makeDailyPlans(goalID: goalID, startDate: start, targetDate: resolvedTarget, templates: generated.dailyChecklist)
        let goal = Goal(
            id: goalID,
            title: generated.title,
            originalDescription: description,
            createdDate: start,
            targetDate: resolvedTarget,
            status: .active,
            selectedModelID: ModelManager.defaultModel.id,
            dailyPlans: plans
        )
        try repository.save(goal)
        goals = try repository.fetchGoals()
    }

    func setChecklistItem(goalID: UUID, itemID: UUID, isCompleted: Bool) throws {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        var updatedGoal = goals[goalIndex]
        for planIndex in updatedGoal.dailyPlans.indices {
            guard let itemIndex = updatedGoal.dailyPlans[planIndex].items.firstIndex(where: { $0.id == itemID }) else { continue }
            updatedGoal.dailyPlans[planIndex].items[itemIndex].isCompleted = isCompleted
            updatedGoal.dailyPlans[planIndex].items[itemIndex].completedDate = isCompleted ? now() : nil
        }
        try repository.save(updatedGoal)
        goals = try repository.fetchGoals()
    }

    func rescaleMissedDay(goalID: UUID, missedDate: Date) throws {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        var updatedGoal = goals[goalIndex]
        updatedGoal.dailyPlans = scheduler.rescaleAfterMissedDay(
            plans: updatedGoal.dailyPlans,
            missedDate: missedDate,
            targetDate: updatedGoal.targetDate
        )
        try repository.save(updatedGoal)
        goals = try repository.fetchGoals()
    }
}

import Foundation
import Observation

enum GoalStoreError: LocalizedError, Equatable {
    case goalNotFound
    case checklistItemNotFound
    case targetDateInPast

    var errorDescription: String? {
        switch self {
        case .goalNotFound:
            AppStrings.string("goalStore.error.goalNotFound")
        case .checklistItemNotFound:
            AppStrings.string("goalStore.error.checklistItemNotFound")
        case .targetDateInPast:
            AppStrings.string("goalStore.error.targetDateInPast")
        }
    }
}

@MainActor
@Observable
final class GoalStore {
    private let repository: GoalRepository
    private let scheduler: GoalScheduler
    private let planningEngine: GoalPlanningEngine
    private let selectedModelID: String
    private let now: () -> Date

    private(set) var goals: [Goal] = []
    var errorMessage: String?

    init(
        repository: GoalRepository,
        scheduler: GoalScheduler,
        planningEngine: GoalPlanningEngine,
        selectedModelID: String = ModelManager.defaultModel.id,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.planningEngine = planningEngine
        self.selectedModelID = selectedModelID
        self.now = now
        do {
            self.goals = try repository.fetchGoals()
        } catch {
            self.goals = []
            self.errorMessage = AppStrings.format("goalStore.error.loadGoals", arguments: [error.localizedDescription])
        }
    }

    func createGoal(description: String, targetDate: Date?) async throws {
        let start = now()
        if let targetDate,
           scheduler.calendar.startOfDay(for: targetDate) < scheduler.calendar.startOfDay(for: start) {
            throw GoalStoreError.targetDateInPast
        }
        let resolvedTarget = scheduler.resolveTargetDate(startDate: start, requestedTargetDate: targetDate)
        let days = scheduler.daysAvailable(from: start, to: resolvedTarget)
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
            selectedModelID: selectedModelID,
            dailyPlans: plans
        )
        try repository.save(goal)
        try refreshGoalsAfterSuccessfulChange()
    }

    func setChecklistItem(goalID: UUID, itemID: UUID, isCompleted: Bool) throws {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else {
            throw GoalStoreError.goalNotFound
        }
        var updatedGoal = goals[goalIndex]
        var didUpdate = false
        for planIndex in updatedGoal.dailyPlans.indices {
            guard let itemIndex = updatedGoal.dailyPlans[planIndex].items.firstIndex(where: { $0.id == itemID }) else { continue }
            updatedGoal.dailyPlans[planIndex].items[itemIndex].isCompleted = isCompleted
            updatedGoal.dailyPlans[planIndex].items[itemIndex].completedDate = isCompleted ? now() : nil
            didUpdate = true
        }
        guard didUpdate else {
            throw GoalStoreError.checklistItemNotFound
        }
        try repository.save(updatedGoal)
        try refreshGoalsAfterSuccessfulChange()
    }

    func rescaleMissedDay(goalID: UUID, missedDate: Date) throws {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else {
            throw GoalStoreError.goalNotFound
        }
        var updatedGoal = goals[goalIndex]
        updatedGoal.dailyPlans = scheduler.rescaleAfterMissedDay(
            plans: updatedGoal.dailyPlans,
            missedDate: missedDate,
            targetDate: updatedGoal.targetDate
        )
        try repository.save(updatedGoal)
        try refreshGoalsAfterSuccessfulChange()
    }

    func reconcileMissedWork() throws {
        let today = scheduler.calendar.startOfDay(for: now())
        var changedGoals: [Goal] = []

        for goal in goals where goal.status == .active {
            var updatedGoal = goal
            for plan in goal.dailyPlans where scheduler.calendar.startOfDay(for: plan.date) < today && plan.items.contains(where: { !$0.isCompleted }) {
                updatedGoal.dailyPlans = scheduler.rescaleAfterMissedDay(
                    plans: updatedGoal.dailyPlans,
                    missedDate: plan.date,
                    targetDate: updatedGoal.targetDate
                )
            }
            if updatedGoal != goal {
                changedGoals.append(updatedGoal)
            }
        }

        guard !changedGoals.isEmpty else { return }
        for goal in changedGoals {
            try repository.save(goal)
        }
        try refreshGoalsAfterSuccessfulChange()
    }

    private func refreshGoalsAfterSuccessfulChange() throws {
        goals = try repository.fetchGoals()
        errorMessage = nil
    }
}

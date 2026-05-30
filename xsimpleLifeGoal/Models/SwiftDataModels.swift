import Foundation
import SwiftData

@Model
final class StoredGoal {
    @Attribute(.unique) var id: UUID
    var title: String
    var originalDescription: String
    var createdDate: Date
    var targetDate: Date
    var statusRawValue: String
    var selectedModelID: String
    @Relationship(deleteRule: .cascade) var dailyPlans: [StoredDailyPlan]

    init(goal: Goal) {
        id = goal.id
        title = goal.title
        originalDescription = goal.originalDescription
        createdDate = goal.createdDate
        targetDate = goal.targetDate
        statusRawValue = goal.status.rawValue
        selectedModelID = goal.selectedModelID
        dailyPlans = goal.dailyPlans.map(StoredDailyPlan.init(plan:))
    }

    func domainValue() -> Goal {
        Goal(
            id: id,
            title: title,
            originalDescription: originalDescription,
            createdDate: createdDate,
            targetDate: targetDate,
            status: GoalStatus(rawValue: statusRawValue) ?? .active,
            selectedModelID: selectedModelID,
            dailyPlans: dailyPlans.map { $0.domainValue(goalID: id) }.sorted { $0.date < $1.date }
        )
    }
}

@Model
final class StoredDailyPlan {
    @Attribute(.unique) var id: UUID
    var goalID: UUID
    var date: Date
    var isRescaled: Bool
    @Relationship(deleteRule: .cascade) var items: [StoredChecklistItem]

    init(plan: DailyPlan) {
        id = plan.id
        goalID = plan.goalID
        date = plan.date
        isRescaled = plan.isRescaled
        items = plan.items.map(StoredChecklistItem.init(item:))
    }

    func domainValue(goalID: UUID) -> DailyPlan {
        DailyPlan(id: id, goalID: goalID, date: date, items: items.map(\.domainValue), isRescaled: isRescaled)
    }
}

@Model
final class StoredChecklistItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var estimatedEffort: String
    var isCompleted: Bool
    var completedDate: Date?

    init(item: ChecklistItem) {
        id = item.id
        text = item.text
        estimatedEffort = item.estimatedEffort
        isCompleted = item.isCompleted
        completedDate = item.completedDate
    }

    var domainValue: ChecklistItem {
        ChecklistItem(id: id, text: text, estimatedEffort: estimatedEffort, isCompleted: isCompleted, completedDate: completedDate)
    }
}

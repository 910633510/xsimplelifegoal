import Foundation
import SwiftData

@MainActor
protocol GoalRepository {
    func fetchGoals() throws -> [Goal]
    func save(_ goal: Goal) throws
}

@MainActor
final class SwiftDataGoalRepository: GoalRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchGoals() throws -> [Goal] {
        let descriptor = FetchDescriptor<StoredGoal>(sortBy: [SortDescriptor(\.createdDate)])
        return try context.fetch(descriptor).map { $0.domainValue() }
    }

    func save(_ goal: Goal) throws {
        let id = goal.id
        let descriptor = FetchDescriptor<StoredGoal>(predicate: #Predicate { $0.id == id })
        for existing in try context.fetch(descriptor) {
            context.delete(existing)
        }
        context.insert(StoredGoal(goal: goal))
        try context.save()
    }
}

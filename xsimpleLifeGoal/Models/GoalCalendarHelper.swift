import Foundation

enum GoalCalendarDayCompletion: Equatable {
    case empty
    case notStarted
    case partial
    case complete
    case rescaled
}

struct GoalCalendarDay: Identifiable, Equatable {
    var id: String {
        if let date {
            return "day-\(Int(date.timeIntervalSinceReferenceDate))"
        }
        return "blank-\(blankIndex)"
    }

    var date: Date?
    var isInGoalRange: Bool
    var completion: GoalCalendarDayCompletion?
    private let blankIndex: Int

    init(date: Date?, isInGoalRange: Bool, completion: GoalCalendarDayCompletion?, blankIndex: Int = 0) {
        self.date = date
        self.isInGoalRange = isInGoalRange
        self.completion = completion
        self.blankIndex = blankIndex
    }
}

enum GoalCalendarHelper {
    static func clampedSelection(preferred date: Date, goal: Goal, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: min(goal.createdDate, goal.targetDate))
        let end = calendar.startOfDay(for: max(goal.createdDate, goal.targetDate))
        let selected = calendar.startOfDay(for: date)

        if selected < start { return start }
        if selected > end { return end }
        return selected
    }

    static func monthStart(containing date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func monthGrid(containing date: Date, goal: Goal, calendar: Calendar) -> [GoalCalendarDay] {
        let monthStart = monthStart(containing: date, calendar: calendar)
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingBlankCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days = (0..<leadingBlankCount).map {
            GoalCalendarDay(date: nil, isInGoalRange: false, completion: nil, blankIndex: $0)
        }

        for day in dayRange {
            guard let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let isInRange = contains(dayDate, goal: goal, calendar: calendar)
            let plan = goal.dailyPlan(on: dayDate, calendar: calendar)
            days.append(GoalCalendarDay(
                date: dayDate,
                isInGoalRange: isInRange,
                completion: isInRange ? completionState(for: plan) : nil
            ))
        }

        while !days.isEmpty && days.count % 7 != 0 {
            days.append(GoalCalendarDay(date: nil, isInGoalRange: false, completion: nil, blankIndex: days.count))
        }
        return days
    }

    static func completionState(for plan: DailyPlan?) -> GoalCalendarDayCompletion {
        guard let plan, !plan.items.isEmpty else { return .empty }
        if plan.isRescaled { return .rescaled }

        let completedCount = plan.items.filter(\.isCompleted).count
        if completedCount == 0 { return .notStarted }
        if completedCount == plan.items.count { return .complete }
        return .partial
    }

    static func contains(_ date: Date, goal: Goal, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: min(goal.createdDate, goal.targetDate))
        let end = calendar.startOfDay(for: max(goal.createdDate, goal.targetDate))
        return day >= start && day <= end
    }

    static func canNavigateToPreviousMonth(from visibleMonth: Date, goal: Goal, calendar: Calendar) -> Bool {
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthStart(containing: visibleMonth, calendar: calendar)) else {
            return false
        }
        return monthIntersectsGoalRange(previousMonth, goal: goal, calendar: calendar)
    }

    static func canNavigateToNextMonth(from visibleMonth: Date, goal: Goal, calendar: Calendar) -> Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart(containing: visibleMonth, calendar: calendar)) else {
            return false
        }
        return monthIntersectsGoalRange(nextMonth, goal: goal, calendar: calendar)
    }

    private static func monthIntersectsGoalRange(_ month: Date, goal: Goal, calendar: Calendar) -> Bool {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return false }
        let start = calendar.startOfDay(for: min(goal.createdDate, goal.targetDate))
        let end = calendar.startOfDay(for: max(goal.createdDate, goal.targetDate))
        let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.start
        return calendar.startOfDay(for: lastDayOfMonth) >= start && calendar.startOfDay(for: monthInterval.start) <= end
    }
}

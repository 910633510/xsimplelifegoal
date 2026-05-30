import Foundation

struct GoalScheduler {
    var calendar: Calendar
    private let makeID: () -> UUID

    init(calendar: Calendar = .current, makeID: @escaping () -> UUID = UUID.init) {
        self.calendar = calendar
        self.makeID = makeID
    }

    func resolveTargetDate(startDate: Date, requestedTargetDate: Date?) -> Date {
        if let requestedTargetDate {
            return calendar.startOfDay(for: requestedTargetDate)
        }
        return calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: startDate))!
    }

    func makeDailyPlans(goalID: UUID, startDate: Date, targetDate: Date, templates: [String]) -> [DailyPlan] {
        let dates = inclusiveDates(from: startDate, through: targetDate)
        let normalizedTemplates = templates.isEmpty ? ["Spend focused time on this goal"] : templates
        return dates.map { date in
            DailyPlan(
                id: makeID(),
                goalID: goalID,
                date: date,
                items: normalizedTemplates.prefix(3).map { text in
                    ChecklistItem(id: makeID(), text: text, estimatedEffort: "Small", isCompleted: false, completedDate: nil)
                },
                isRescaled: false
            )
        }
    }

    func rescaleAfterMissedDay(plans: [DailyPlan], missedDate: Date, targetDate: Date) -> [DailyPlan] {
        let missedDay = calendar.startOfDay(for: missedDate)
        let remainingDates = inclusiveDates(
            from: calendar.date(byAdding: .day, value: 1, to: missedDay) ?? missedDay,
            through: targetDate
        )
        guard !remainingDates.isEmpty else { return plans }

        let catchUpMarker = catchUpMarker(for: missedDay)
        let hasAlreadyRescaledMissedDay = plans.contains { plan in
            remainingDates.contains { calendar.isDate($0, inSameDayAs: plan.date) }
                && plan.items.contains { $0.text.hasPrefix(catchUpMarker) }
        }
        guard !hasAlreadyRescaledMissedDay else { return plans }

        let missedItems = plans
            .filter { calendar.isDate($0.date, inSameDayAs: missedDay) }
            .flatMap(\.items)
            .filter { !$0.isCompleted }

        guard !missedItems.isEmpty else { return plans }

        var itemBuckets = Array(repeating: [ChecklistItem](), count: remainingDates.count)
        for (index, item) in missedItems.enumerated() {
            var redistributed = item
            redistributed.id = makeID()
            redistributed.text = catchUpText(for: item.text, missedDay: missedDay)
            redistributed.isCompleted = false
            redistributed.completedDate = nil
            itemBuckets[index % itemBuckets.count].append(redistributed)
        }

        return plans.map { plan in
            guard let dateIndex = remainingDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: plan.date) }) else {
                return plan
            }
            var updated = plan
            // Rescale preserves missed work, so remaining days may exceed the base three-item cap.
            updated.items.append(contentsOf: itemBuckets[dateIndex])
            updated.isRescaled = true
            return updated
        }
    }

    private func inclusiveDates(from startDate: Date, through targetDate: Date) -> [Date] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: max(startDate, targetDate))
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }

    private func catchUpText(for text: String, missedDay: Date) -> String {
        "\(catchUpMarker(for: missedDay))\(text)"
    }

    private func catchUpMarker(for missedDay: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: missedDay)
        return String(
            format: "[catch-up %04d-%02d-%02d] ",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

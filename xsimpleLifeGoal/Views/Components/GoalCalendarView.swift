import SwiftUI

struct GoalCalendarView: View {
    @Environment(\.calendar) private var calendar

    let goal: Goal
    let visibleMonth: Date
    let selectedDate: Date
    let onSelectDate: (Date) -> Void
    let onShowPreviousMonth: () -> Void
    let onShowNextMonth: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(minimum: 32), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button(action: onShowPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!GoalCalendarHelper.canNavigateToPreviousMonth(from: visibleMonth, goal: goal, calendar: calendar))
                .accessibilityLabel(AppStrings.key("calendar.previousMonth.accessibility"))

                Spacer()

                Text(monthTitle)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)

                Spacer()

                Button(action: onShowNextMonth) {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!GoalCalendarHelper.canNavigateToNextMonth(from: visibleMonth, goal: goal, calendar: calendar))
                .accessibilityLabel(AppStrings.key("calendar.nextMonth.accessibility"))
            }
            .foregroundStyle(AppTheme.accent)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                        .frame(maxWidth: .infinity, minHeight: 18)
                }

                ForEach(GoalCalendarHelper.monthGrid(containing: visibleMonth, goal: goal, calendar: calendar)) { day in
                    GoalCalendarDayButton(
                        day: day,
                        selectedDate: selectedDate,
                        onSelectDate: onSelectDate
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var monthTitle: String {
        visibleMonth.formatted(.dateTime.month(.wide).year())
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let startIndex = max(calendar.firstWeekday - 1, 0)
        return symbols.indices.map { offset in
            symbols[(offset + startIndex) % symbols.count]
        }
    }
}

private struct GoalCalendarDayButton: View {
    @Environment(\.calendar) private var calendar

    let day: GoalCalendarDay
    let selectedDate: Date
    let onSelectDate: (Date) -> Void

    var body: some View {
        Group {
            if let date = day.date {
                Button {
                    onSelectDate(date)
                } label: {
                    VStack(spacing: 3) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                        completionMarker
                    }
                    .foregroundStyle(isSelected ? Color.white : AppTheme.ink)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(isSelected ? AppTheme.accent : dayBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(todayStroke(for: date))
                    .opacity(day.isInGoalRange ? 1 : 0.32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!day.isInGoalRange)
                .accessibilityLabel(accessibilityLabel(for: date))
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 42)
            }
        }
    }

    @ViewBuilder
    private var completionMarker: some View {
        switch day.completion {
        case .empty, .none:
            Circle()
                .fill(Color.clear)
                .frame(width: 6, height: 6)
        case .notStarted:
            Circle()
                .stroke(isSelected ? Color.white.opacity(0.7) : AppTheme.muted, lineWidth: 1)
                .frame(width: 6, height: 6)
        case .partial:
            Circle()
                .fill(isSelected ? Color.white : AppTheme.warm)
                .frame(width: 6, height: 6)
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.white : AppTheme.accent)
        case .rescaled:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.white : AppTheme.warm)
        }
    }

    private var isSelected: Bool {
        guard let date = day.date else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }

    @ViewBuilder
    private func todayStroke(for date: Date) -> some View {
        if calendar.isDateInToday(date) && !isSelected {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppTheme.warm, lineWidth: 1)
        }
    }

    private var dayBackground: Color {
        day.isInGoalRange ? AppTheme.accentSoft.opacity(0.28) : Color.clear
    }

    private func accessibilityLabel(for date: Date) -> String {
        let dateText = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        switch day.completion {
        case .empty, .none:
            return AppStrings.format("calendar.day.noWork", arguments: [dateText])
        case .notStarted:
            return AppStrings.format("calendar.day.notStarted", arguments: [dateText])
        case .partial:
            return AppStrings.format("calendar.day.partial", arguments: [dateText])
        case .complete:
            return AppStrings.format("calendar.day.complete", arguments: [dateText])
        case .rescaled:
            return AppStrings.format("calendar.day.rescaled", arguments: [dateText])
        }
    }
}

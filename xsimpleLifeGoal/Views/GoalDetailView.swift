import SwiftUI

struct GoalDetailView: View {
    @Environment(\.calendar) private var calendar
    @Bindable var store: GoalStore
    let goalID: UUID
    @State private var selectedDate: Date?
    @State private var visibleMonth: Date?
    @State private var errorMessage: String?

    private var goal: Goal? {
        store.goals.first { $0.id == goalID }
    }

    var body: some View {
        ScrollView {
            if let goal {
                let activeSelectedDate = selectedDate(for: goal)
                let activeVisibleMonth = visibleMonth(for: goal, selectedDate: activeSelectedDate)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(AppStrings.key("goalDetail.defaultTitle"), systemImage: "target")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                        Text(goal.originalDescription)
                            .font(.body)
                            .foregroundStyle(AppTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )

                    GoalCalendarView(
                        goal: goal,
                        visibleMonth: activeVisibleMonth,
                        selectedDate: activeSelectedDate,
                        onSelectDate: { date in
                            selectedDate = date
                            visibleMonth = GoalCalendarHelper.monthStart(containing: date, calendar: calendar)
                        },
                        onShowPreviousMonth: {
                            visibleMonth = calendar.date(byAdding: .month, value: -1, to: activeVisibleMonth)
                        },
                        onShowNextMonth: {
                            visibleMonth = calendar.date(byAdding: .month, value: 1, to: activeVisibleMonth)
                        }
                    )

                    if let plan = goal.dailyPlan(on: activeSelectedDate, calendar: calendar) {
                        DailyChecklistView(title: checklistTitle(for: activeSelectedDate), plan: plan) { itemID, isCompleted in
                            setChecklistItem(itemID: itemID, isCompleted: isCompleted)
                        }
                    } else {
                        Label(
                            AppStrings.format("goalDetail.noWorkScheduled", arguments: [checklistTitle(for: activeSelectedDate)]),
                            systemImage: "moon"
                        )
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    }

                    ProgressSummaryView(goal: goal)

                    Button {
                        rescaleMissedWork()
                    } label: {
                        Label(AppStrings.key("goalDetail.rescaleButton"), systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }
                .padding()
            } else {
                ContentUnavailableView(AppStrings.key("goalDetail.notFound"), systemImage: "target")
                    .frame(maxWidth: .infinity, minHeight: 360)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(goal?.title ?? AppStrings.string("goalDetail.defaultTitle"))
        .alert(AppStrings.string("goalDetail.alertTitle"), isPresented: isShowingError) {
            Button(AppStrings.string("common.ok"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? AppStrings.string("common.tryAgain"))
        }
    }

    private func selectedDate(for goal: Goal) -> Date {
        GoalCalendarHelper.clampedSelection(preferred: selectedDate ?? Date(), goal: goal, calendar: calendar)
    }

    private func visibleMonth(for goal: Goal, selectedDate: Date) -> Date {
        let preferredMonth = GoalCalendarHelper.monthStart(containing: visibleMonth ?? selectedDate, calendar: calendar)
        let monthHasGoalDays = GoalCalendarHelper.monthGrid(containing: preferredMonth, goal: goal, calendar: calendar)
            .contains { $0.date != nil && $0.isInGoalRange }
        if monthHasGoalDays {
            return preferredMonth
        }
        return GoalCalendarHelper.monthStart(containing: selectedDate, calendar: calendar)
    }

    private func checklistTitle(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func setChecklistItem(itemID: UUID, isCompleted: Bool) {
        do {
            try store.setChecklistItem(goalID: goalID, itemID: itemID, isCompleted: isCompleted)
        } catch {
            errorMessage = AppStrings.format("goalDetail.error.updateChecklist", arguments: [error.localizedDescription])
        }
    }

    private func rescaleMissedWork() {
        do {
            try store.rescaleMissedDay(goalID: goalID, missedDate: Date())
        } catch {
            errorMessage = AppStrings.format("goalDetail.error.rescale", arguments: [error.localizedDescription])
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }
}

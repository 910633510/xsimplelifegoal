import SwiftUI

struct GoalDetailView: View {
    @Environment(\.calendar) private var calendar
    @Bindable var store: GoalStore
    let goalID: UUID
    @State private var errorMessage: String?

    private var goal: Goal? {
        store.goals.first { $0.id == goalID }
    }

    var body: some View {
        ScrollView {
            if let goal {
                VStack(alignment: .leading, spacing: 16) {
                    Text(goal.originalDescription)
                        .font(.body)
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))

                    if let plan = goal.dailyPlan(on: Date(), calendar: calendar) {
                        DailyChecklistView(plan: plan) { itemID, isCompleted in
                            setChecklistItem(itemID: itemID, isCompleted: isCompleted)
                        }
                    } else {
                        Text("No checklist yet")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                    }

                    ProgressSummaryView(goal: goal)

                    Button {
                        rescaleMissedWork()
                    } label: {
                        Text("Rescale Missed Work")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }
                .padding()
            } else {
                ContentUnavailableView("Goal Not Found", systemImage: "target")
                    .frame(maxWidth: .infinity, minHeight: 360)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(goal?.title ?? "Goal")
        .alert("Goal Update Failed", isPresented: isShowingError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func setChecklistItem(itemID: UUID, isCompleted: Bool) {
        do {
            try store.setChecklistItem(goalID: goalID, itemID: itemID, isCompleted: isCompleted)
        } catch {
            errorMessage = "Unable to update this checklist item. \(error.localizedDescription)"
        }
    }

    private func rescaleMissedWork() {
        do {
            try store.rescaleMissedDay(goalID: goalID, missedDate: Date())
        } catch {
            errorMessage = "Unable to rescale this goal. \(error.localizedDescription)"
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

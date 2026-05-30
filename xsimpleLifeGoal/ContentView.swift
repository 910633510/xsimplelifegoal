import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var setupViewModel = ModelSetupViewModel()

    var body: some View {
        Group {
            if !setupViewModel.isReady && !setupViewModel.allowsDashboardWithoutReadyModel {
                ModelSetupView(viewModel: setupViewModel)
            } else {
                GoalStoreRootView(modelContext: modelContext)
            }
        }
    }
}

private struct GoalStoreRootView: View {
    let modelContext: ModelContext
    @State private var store: GoalStore?

    var body: some View {
        Group {
            if let store {
                GoalDashboardView(store: store)
            } else {
                ProgressView()
                    .task {
                        initializeStoreIfNeeded()
                    }
            }
        }
        .onAppear {
            initializeStoreIfNeeded()
        }
    }

    @MainActor
    private func initializeStoreIfNeeded() {
        guard store == nil else { return }
        let repository = SwiftDataGoalRepository(context: modelContext)
        let planner = GoalPlanningEngine(generator: UnavailableTextGenerator())
        store = GoalStore(repository: repository, scheduler: GoalScheduler(), planningEngine: planner)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StoredGoal.self, StoredDailyPlan.self, StoredChecklistItem.self], inMemory: true)
}

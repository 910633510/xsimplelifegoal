import SwiftUI

struct GoalDashboardView: View {
    @Bindable var store: GoalStore
    @State private var showingCreation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.goals) { goal in
                            NavigationLink(value: goal.id) {
                                GoalCard(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Life Goals")
            .toolbar {
                Button {
                    showingCreation = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Goal")
            }
            .sheet(isPresented: $showingCreation) {
                GoalCreationView(store: store)
            }
            .navigationDestination(for: UUID.self) { goalID in
                GoalDetailView(store: store, goalID: goalID)
            }
        }
    }
}

import SwiftUI

struct GoalDashboardView: View {
    @Bindable var store: GoalStore
    @State private var showingCreation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(AppStrings.key("dashboard.greeting"), systemImage: "sun.max.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.warm)
                            Text(AppStrings.key("dashboard.subtitle"))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                        if store.goals.isEmpty {
                            EmptyGoalsView {
                                showingCreation = true
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(store.goals) { goal in
                                    NavigationLink(value: goal.id) {
                                        GoalCard(goal: goal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(AppStrings.key("dashboard.title"))
            .toolbar {
                Button {
                    showingCreation = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(AppStrings.key("dashboard.newGoal.accessibility"))
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

private struct EmptyGoalsView: View {
    let onAddGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.warm)
                .accessibilityHidden(true)
            Text(AppStrings.key("dashboard.empty.title"))
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text(AppStrings.key("dashboard.empty.message"))
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onAddGoal) {
                Label(AppStrings.key("dashboard.empty.addGoal"), systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

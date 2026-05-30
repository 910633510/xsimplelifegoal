import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("\(Int(goal.progressFraction * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            ProgressView(value: goal.progressFraction)
                .tint(AppTheme.accent)

            Text(todaySummary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var todaySummary: String {
        goal.checklistSummary(on: Date(), calendar: .current)
    }
}

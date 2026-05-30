import SwiftUI

struct ProgressSummaryView: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            ProgressView(value: goal.progressFraction)
                .tint(AppTheme.accent)

            Text("\(Int(goal.progressFraction * 100))% complete")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
    }
}

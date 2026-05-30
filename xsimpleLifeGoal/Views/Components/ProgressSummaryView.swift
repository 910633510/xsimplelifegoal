import SwiftUI

struct ProgressSummaryView: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(AppStrings.key("progress.title"), systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            ProgressView(value: goal.progressFraction)
                .tint(AppTheme.accent)

            Text(AppStrings.format("progress.complete", arguments: [Int(goal.progressFraction * 100)]))
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

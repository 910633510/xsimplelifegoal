import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                        .fill(AppTheme.accentSoft)
                        .frame(width: 38, height: 38)
                    Image(systemName: "target")
                        .foregroundStyle(AppTheme.accent)
                        .font(.headline)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(AppStrings.key("goalCard.today"), systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()
                Text(progressText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            ProgressView(value: goal.progressFraction)
                .tint(AppTheme.accent)

            Text(todaySummary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }

    private var todaySummary: String {
        goal.checklistSummary(on: Date(), calendar: .current)
    }

    private var progressText: String {
        "\(Int(goal.progressFraction * 100))%"
    }
}

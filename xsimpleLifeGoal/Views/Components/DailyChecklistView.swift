import SwiftUI

struct DailyChecklistView: View {
    let title: String
    let plan: DailyPlan
    let onToggle: (UUID, Bool) -> Void

    init(title: String? = nil, plan: DailyPlan, onToggle: @escaping (UUID, Bool) -> Void) {
        self.title = title ?? AppStrings.string("dailyChecklist.defaultTitle")
        self.plan = plan
        self.onToggle = onToggle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 8) {
                ForEach(plan.items) { item in
                    Button {
                        onToggle(item.id, !item.isCompleted)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(item.isCompleted ? AppTheme.accent : AppTheme.muted)
                            Text(item.text)
                                .font(.body)
                                .foregroundStyle(AppTheme.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(
                        item.isCompleted
                            ? AppStrings.string("dailyChecklist.completed.accessibility")
                            : AppStrings.string("dailyChecklist.notCompleted.accessibility")
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
}

import SwiftUI

struct DailyChecklistView: View {
    let plan: DailyPlan
    let onToggle: (UUID, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 10) {
                ForEach(plan.items) { item in
                    Button {
                        onToggle(item.id, !item.isCompleted)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isCompleted ? AppTheme.accent : AppTheme.muted)
                            Text(item.text)
                                .font(.body)
                                .foregroundStyle(AppTheme.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
    }
}

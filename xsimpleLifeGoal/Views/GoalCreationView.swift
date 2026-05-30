import SwiftUI

struct GoalCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: GoalStore
    @State private var description = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(60 * 60 * 24 * 365)
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(AppStrings.key("goalCreation.taskTitle"), systemImage: "pencil.and.list.clipboard")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $description)
                                    .frame(minHeight: 140)
                                    .scrollContentBackground(.hidden)
                                    .foregroundStyle(AppTheme.ink)
                                    .padding(8)

                                if description.isEmpty {
                                    Text(AppStrings.key("goalCreation.taskPrompt"))
                                        .font(.body)
                                        .foregroundStyle(AppTheme.muted)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .background(AppTheme.cardAlt)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )

                            Text(AppStrings.key("goalCreation.taskHint"))
                                .font(.footnote)
                                .foregroundStyle(AppTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 12) {
                            Label(AppStrings.key("goalCreation.timelineTitle"), systemImage: "calendar")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)

                            Toggle(isOn: $hasDeadline) {
                                Text(AppStrings.key("goalCreation.setCompletionDate"))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            .tint(AppTheme.accent)

                            if hasDeadline {
                                DatePicker(
                                    AppStrings.key("goalCreation.deadline"),
                                    selection: $deadline,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .tint(AppTheme.accent)
                            }

                            Text(AppStrings.key("goalCreation.timelineHint"))
                                .font(.footnote)
                                .foregroundStyle(AppTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)

                        Button {
                            Task { await createGoal() }
                        } label: {
                            if isGenerating {
                                Label(AppStrings.key("goalCreation.generatingButton"), systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label(AppStrings.key("goalCreation.generateButton"), systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                        .disabled(isCreateDisabled)
                    }
                    .padding()
                }
            }
            .navigationTitle(AppStrings.key("goalCreation.title"))
            .toolbar {
                Button(AppStrings.key("common.cancel")) { dismiss() }
            }
            .alert(AppStrings.string("goalCreation.alertTitle"), isPresented: isShowingError) {
                Button(AppStrings.string("common.ok"), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? AppStrings.string("common.tryAgain"))
            }
        }
    }

    private func createGoal() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            try await store.createGoal(description: description, targetDate: hasDeadline ? deadline : nil)
            dismiss()
        } catch {
            errorMessage = AppStrings.format("goalCreation.error.create", arguments: [error.localizedDescription])
        }
    }

    private var isCreateDisabled: Bool {
        description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating
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

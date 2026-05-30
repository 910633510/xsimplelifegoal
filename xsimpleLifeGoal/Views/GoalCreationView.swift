import SwiftUI

struct GoalCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: GoalStore
    @State private var description = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(60 * 60 * 24 * 365)
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }

                Section("Timeline") {
                    Toggle("Set completion date", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    }
                }

                Section {
                    Button {
                        Task { await createGoal() }
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Generate Daily Plan")
                        }
                    }
                    .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func createGoal() async {
        isGenerating = true
        defer { isGenerating = false }
        try? await store.createGoal(description: description, targetDate: hasDeadline ? deadline : nil)
        dismiss()
    }
}

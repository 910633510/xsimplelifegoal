import Foundation

protocol TextGenerating: Sendable {
    func generateText(prompt: String) async throws -> String
}

struct GeneratedGoalPlan: Equatable {
    var title: String
    var dailyChecklist: [String]
    var usedFallback: Bool
}

struct GoalPlanningEngine: Sendable {
    private let generator: TextGenerating

    init(generator: TextGenerating) {
        self.generator = generator
    }

    func generatePlan(description: String, daysAvailable: Int) async throws -> GeneratedGoalPlan {
        let prompt = Self.prompt(description: description, daysAvailable: daysAvailable)
        do {
            let text = try await generator.generateText(prompt: prompt)
            return try parse(text)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return fallback(description: description)
        }
    }

    private func parse(_ text: String) throws -> GeneratedGoalPlan {
        struct Payload: Decodable {
            let title: String
            let dailyChecklist: [String]
        }

        guard let data = text.data(using: .utf8) else {
            throw PlanningError.invalidOutput
        }

        let payload = try JSONDecoder().decode(Payload.self, from: data)
        let checklist = payload.dailyChecklist
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)

        guard !payload.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !checklist.isEmpty else {
            throw PlanningError.invalidOutput
        }

        return GeneratedGoalPlan(
            title: payload.title.trimmingCharacters(in: .whitespacesAndNewlines),
            dailyChecklist: Array(checklist),
            usedFallback: false
        )
    }

    private func fallback(description: String) -> GeneratedGoalPlan {
        let title = description
            .split(separator: " ")
            .prefix(6)
            .map { word in word.prefix(1).uppercased() + word.dropFirst() }
            .joined(separator: " ")

        return GeneratedGoalPlan(
            title: title.isEmpty ? "New Goal" : title,
            dailyChecklist: [
                "Spend 20 focused minutes on \(description)",
                "Record one concrete step you completed",
                "Choose the next small action"
            ],
            usedFallback: true
        )
    }

    static func prompt(description: String, daysAvailable: Int) -> String {
        """
        You are a practical life-goal planner. Return compact JSON only.
        User goal: \(description)
        Days available: \(daysAvailable)
        Schema: {"title":"short title","dailyChecklist":["action 1","action 2","action 3"]}
        Each action must be specific, checkable, and possible in one day.
        """
    }
}

enum PlanningError: Error {
    case invalidOutput
}

struct UnavailableTextGenerator: TextGenerating {
    func generateText(prompt: String) async throws -> String {
        throw PlanningError.invalidOutput
    }
}

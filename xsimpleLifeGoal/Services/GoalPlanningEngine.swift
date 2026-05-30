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
    private let locale: Locale

    init(generator: TextGenerating, locale: Locale = .autoupdatingCurrent) {
        self.generator = generator
        self.locale = locale
    }

    func generatePlan(description: String, daysAvailable: Int) async throws -> GeneratedGoalPlan {
        let prompt = Self.prompt(description: description, daysAvailable: daysAvailable, locale: locale)
        do {
            let text = try await generator.generateText(prompt: prompt)
            return try parse(text)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return fallback(description: description, locale: locale)
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

    private func fallback(description: String, locale: Locale) -> GeneratedGoalPlan {
        let language = AppLanguage.resolved(for: locale)
        if language == .simplifiedChinese {
            let localeIdentifier = language.localeIdentifier
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = trimmedDescription.isEmpty
                ? AppStrings.string("planning.fallback.title.empty", localeIdentifier: localeIdentifier)
                : String(trimmedDescription.prefix(12))
            return GeneratedGoalPlan(
                title: title,
                dailyChecklist: [
                    AppStrings.format("planning.fallback.item.focus", localeIdentifier: localeIdentifier, arguments: [trimmedDescription.isEmpty ? title : trimmedDescription]),
                    AppStrings.string("planning.fallback.item.record", localeIdentifier: localeIdentifier),
                    AppStrings.string("planning.fallback.item.next", localeIdentifier: localeIdentifier)
                ],
                usedFallback: true
            )
        }

        let title = description
            .split(separator: " ")
            .prefix(6)
            .map { word in word.prefix(1).uppercased() + word.dropFirst() }
            .joined(separator: " ")

        return GeneratedGoalPlan(
            title: title.isEmpty ? AppStrings.string("planning.fallback.title.empty", localeIdentifier: language.localeIdentifier) : title,
            dailyChecklist: [
                AppStrings.format("planning.fallback.item.focus", localeIdentifier: language.localeIdentifier, arguments: [description]),
                AppStrings.string("planning.fallback.item.record", localeIdentifier: language.localeIdentifier),
                AppStrings.string("planning.fallback.item.next", localeIdentifier: language.localeIdentifier)
            ],
            usedFallback: true
        )
    }

    static func prompt(description: String, daysAvailable: Int, locale: Locale = .autoupdatingCurrent) -> String {
        if AppLanguage.resolved(for: locale) == .simplifiedChinese {
            return """
            你是一位实用的人生目标规划助手。请使用简体中文，只返回可直接解析的 JSON。
            用户目标：\(description)
            可用天数：\(daysAvailable)
            Schema: {"title":"简短标题","dailyChecklist":["行动 1","行动 2","行动 3"]}
            每个行动都必须具体、可检查，并且能在一天内完成。
            """
        }

        return """
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

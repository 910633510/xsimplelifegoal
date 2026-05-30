import XCTest
@testable import xsimpleLifeGoal

final class GoalPlanningEngineTests: XCTestCase {
    func testParsesStructuredModelOutput() async throws {
        let output = """
        {"title":"Learn Spanish","dailyChecklist":["Review 15 phrases","Speak for 5 minutes","Log one phrase"]}
        """
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: output))

        let plan = try await engine.generatePlan(description: "learn conversational Spanish", daysAvailable: 365)

        XCTAssertEqual(plan.title, "Learn Spanish")
        XCTAssertEqual(plan.dailyChecklist, ["Review 15 phrases", "Speak for 5 minutes", "Log one phrase"])
        XCTAssertFalse(plan.usedFallback)
    }

    func testInvalidModelOutputUsesDeterministicFallback() async throws {
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: "not json"), locale: Locale(identifier: "en"))

        let plan = try await engine.generatePlan(description: "prepare for a marathon", daysAvailable: 120)

        XCTAssertEqual(plan.title, "Prepare For A Marathon")
        XCTAssertEqual(plan.dailyChecklist.count, 3)
        XCTAssertTrue(plan.usedFallback)
    }

    func testSimplifiedChineseLocalePromptRequestsSimplifiedChineseJSON() async throws {
        let generator = CapturingTextGenerator(result: #"{"title":"学习西班牙语","dailyChecklist":["复习 15 个短语","开口练习 5 分钟","记录一句新表达"]}"#)
        let engine = GoalPlanningEngine(generator: generator, locale: Locale(identifier: "zh-Hans"))

        _ = try await engine.generatePlan(description: "学习日常西班牙语", daysAvailable: 30)

        let capturedPrompt = await generator.capturedPrompt()
        let prompt = try XCTUnwrap(capturedPrompt)
        XCTAssertTrue(prompt.contains("请使用简体中文"))
        XCTAssertTrue(prompt.contains("可直接解析的 JSON"))
        XCTAssertTrue(prompt.contains("可检查"))
    }

    func testSimplifiedChineseLocaleUsesChineseFallbackWhenModelOutputIsInvalid() async throws {
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: "not json"), locale: Locale(identifier: "zh-Hans"))

        let plan = try await engine.generatePlan(description: "准备马拉松", daysAvailable: 120)

        XCTAssertEqual(plan.title, "准备马拉松")
        XCTAssertEqual(plan.dailyChecklist, [
            "专注 20 分钟推进：准备马拉松",
            "记录今天完成的一个具体进展",
            "选出明天最小的下一步行动"
        ])
        XCTAssertTrue(plan.usedFallback)
    }

    func testGeneratorCancellationPropagates() async throws {
        let engine = GoalPlanningEngine(generator: CancellingTextGenerator())

        do {
            _ = try await engine.generatePlan(description: "write a novel", daysAvailable: 365)
            XCTFail("Expected CancellationError to propagate.")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected CancellationError, got \(error).")
        }
    }

    func testLocalLLMServiceReportsRuntimeUnavailableWithoutFramework() async throws {
        guard !LocalLLMService.isRuntimeAvailable else {
            throw XCTSkip("llama runtime is available in this environment.")
        }

        let service = LocalLLMService()

        do {
            _ = try await service.generateText(prompt: "Return JSON")
            XCTFail("Expected runtime unavailable error")
        } catch LocalLLMError.runtimeUnavailable {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLocalLLMServiceReportsMissingModelFileWhenRuntimeAvailable() async throws {
        guard LocalLLMService.isRuntimeAvailable else {
            throw XCTSkip("llama runtime is not available in this environment.")
        }

        let missingModelURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gguf")
        let service = LocalLLMService(modelURL: missingModelURL)

        do {
            _ = try await service.generateText(prompt: "Return JSON")
            XCTFail("Expected missing model file error")
        } catch LocalLLMError.modelFileMissing {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct FixtureTextGenerator: TextGenerating {
    let result: String

    func generateText(prompt: String) async throws -> String {
        result
    }
}

private struct CancellingTextGenerator: TextGenerating {
    func generateText(prompt: String) async throws -> String {
        throw CancellationError()
    }
}

private actor CapturingTextGenerator: TextGenerating {
    let result: String
    private var prompt: String?

    init(result: String) {
        self.result = result
    }

    func generateText(prompt: String) async throws -> String {
        self.prompt = prompt
        return result
    }

    func capturedPrompt() -> String? {
        prompt
    }
}

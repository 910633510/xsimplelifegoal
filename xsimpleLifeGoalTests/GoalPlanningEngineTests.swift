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
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: "not json"))

        let plan = try await engine.generatePlan(description: "prepare for a marathon", daysAvailable: 120)

        XCTAssertEqual(plan.title, "Prepare For A Marathon")
        XCTAssertEqual(plan.dailyChecklist.count, 3)
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

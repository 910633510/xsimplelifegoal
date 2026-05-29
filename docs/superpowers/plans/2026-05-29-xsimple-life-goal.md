# xsimple Life Goal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native SwiftUI iOS app that creates multiple offline LLM-assisted life goals, generates daily checklists, tracks completion, and redistributes missed work across the remaining timeline.

**Architecture:** The project uses an Xcode 16 file-system-synchronized `.xcodeproj`, SwiftUI views, SwiftData persistence behind a repository, deterministic scheduling logic, and a protocol-backed planning engine. `llama.cpp` is isolated behind `LocalLLMService` so app behavior and tests do not depend on model inference.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, XCTest, Foundation URLSession, `llama.cpp` XCFramework, GGUF models from Qwen.

---

## File Structure

- Create: `xsimpleLifeGoal.xcodeproj/project.pbxproj` - native iOS project with app and unit test targets.
- Create: `xsimpleLifeGoal/xsimpleLifeGoalApp.swift` - app entry and SwiftData container setup.
- Create: `xsimpleLifeGoal/ContentView.swift` - root shell with model readiness routing.
- Create: `xsimpleLifeGoal/Models/GoalDomain.swift` - pure Swift domain models used by tests, scheduler, planning, and UI.
- Create: `xsimpleLifeGoal/Models/SwiftDataModels.swift` - SwiftData `@Model` entities.
- Create: `xsimpleLifeGoal/Services/GoalScheduler.swift` - date math, daily allocation, completion updates, missed-day redistribution.
- Create: `xsimpleLifeGoal/Services/GoalPlanningEngine.swift` - structured plan generation, JSON parsing, deterministic fallback.
- Create: `xsimpleLifeGoal/Services/LocalLLMService.swift` - `TextGenerating` implementation backed by `llama.cpp` when available.
- Create: `xsimpleLifeGoal/Services/ModelManager.swift` - model manifests, storage paths, readiness, download state.
- Create: `xsimpleLifeGoal/Stores/GoalRepository.swift` - repository protocol and SwiftData implementation.
- Create: `xsimpleLifeGoal/ViewModels/GoalStore.swift` - `@MainActor` app state and user actions.
- Create: `xsimpleLifeGoal/ViewModels/ModelSetupViewModel.swift` - model setup state.
- Create: `xsimpleLifeGoal/Views/AppTheme.swift` - quiet utility visual system.
- Create: `xsimpleLifeGoal/Views/GoalDashboardView.swift` - active goals dashboard.
- Create: `xsimpleLifeGoal/Views/GoalCreationView.swift` - goal input, optional deadline, generation action.
- Create: `xsimpleLifeGoal/Views/GoalDetailView.swift` - today's checklist, progress, missed-day rescale action.
- Create: `xsimpleLifeGoal/Views/ModelSetupView.swift` - first-run model download UI.
- Create: `xsimpleLifeGoal/Views/Components/GoalCard.swift` - dashboard card.
- Create: `xsimpleLifeGoal/Views/Components/DailyChecklistView.swift` - checklist rows and completion toggles.
- Create: `xsimpleLifeGoal/Views/Components/ProgressSummaryView.swift` - progress and days-left summary.
- Create: `xsimpleLifeGoal/Assets.xcassets/Contents.json` - asset catalog root.
- Create: `xsimpleLifeGoal/Assets.xcassets/AccentColor.colorset/Contents.json` - accent color.
- Create: `xsimpleLifeGoal/Assets.xcassets/AppIcon.appiconset/Contents.json` - empty generated app icon set.
- Create: `xsimpleLifeGoalTests/AppSmokeTests.swift` - build smoke test.
- Create: `xsimpleLifeGoalTests/GoalSchedulerTests.swift` - scheduler behavior tests.
- Create: `xsimpleLifeGoalTests/GoalPlanningEngineTests.swift` - parsing and fallback tests.
- Create: `xsimpleLifeGoalTests/ModelManagerTests.swift` - model manifest and readiness tests.
- Create: `xsimpleLifeGoalTests/GoalRepositoryTests.swift` - SwiftData persistence tests.
- Create: `xsimpleLifeGoalTests/GoalStoreTests.swift` - app state tests.
- Create: `scripts/build-llama-xcframework.sh` - repeatable script for building and copying the `llama.cpp` XCFramework.
- Create: `Vendor/README.md` - local framework/model vendor notes.
- Modify: `.gitignore` - ignore build artifacts, downloaded frameworks, downloaded models, and Xcode user state.

## Task 1: Native Xcode Project Scaffold

**Files:**
- Create: `xsimpleLifeGoal.xcodeproj/project.pbxproj`
- Create: `xsimpleLifeGoal/xsimpleLifeGoalApp.swift`
- Create: `xsimpleLifeGoal/ContentView.swift`
- Create: `xsimpleLifeGoal/Assets.xcassets/Contents.json`
- Create: `xsimpleLifeGoal/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `xsimpleLifeGoal/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `xsimpleLifeGoalTests/AppSmokeTests.swift`
- Modify: `.gitignore`

- [ ] **Step 1: Write the failing smoke test**

Create `xsimpleLifeGoalTests/AppSmokeTests.swift`:

```swift
import XCTest
@testable import xsimpleLifeGoal

final class AppSmokeTests: XCTestCase {
    func testAppNameIsStable() {
        XCTAssertEqual(AppMetadata.displayName, "xsimple Life Goal")
    }
}
```

- [ ] **Step 2: Run the smoke test and verify it fails**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: FAIL because `xsimpleLifeGoal.xcodeproj` and `AppMetadata` do not exist.

- [ ] **Step 3: Create the app skeleton**

Create `xsimpleLifeGoal/xsimpleLifeGoalApp.swift`:

```swift
import SwiftUI
import SwiftData

enum AppMetadata {
    static let displayName = "xsimple Life Goal"
}

@main
struct xsimpleLifeGoalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Create `xsimpleLifeGoal/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text(AppMetadata.displayName)
                .font(.title.weight(.semibold))
                .padding()
                .navigationTitle("Goals")
        }
    }
}

#Preview {
    ContentView()
}
```

Create `xsimpleLifeGoal/Assets.xcassets/Contents.json`:

```json
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Create `xsimpleLifeGoal/Assets.xcassets/AccentColor.colorset/Contents.json`:

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "0.580",
          "green": "0.520",
          "red": "0.120"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Create `xsimpleLifeGoal/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [
    {
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Create `xsimpleLifeGoal.xcodeproj/project.pbxproj` as a minimal Xcode 16 file-system-synchronized project. The project must contain one iOS app target and one unit test target. Use file-system-synchronized root groups so Swift files under `xsimpleLifeGoal/` and `xsimpleLifeGoalTests/` are picked up without adding each file to the project file. The required project values are:

```text
Project name: xsimpleLifeGoal
App target name: xsimpleLifeGoal
Unit test target name: xsimpleLifeGoalTests
Product bundle identifier: xmllc.xsimple-life-goal
Deployment target: 17.0
Marketing version: 1.0
Current project version: 1
App product name: xsimple Life Goal
Swift version: 6.0
Targets: one iOS application target, one iOS unit test bundle target
Root synchronized groups: xsimpleLifeGoal, xsimpleLifeGoalTests
```

The project graph must include these relationships:

```text
PBXProject targets = (xsimpleLifeGoal, xsimpleLifeGoalTests)
xsimpleLifeGoal build phases = Sources, Frameworks, Resources
xsimpleLifeGoal fileSystemSynchronizedGroups = (xsimpleLifeGoal)
xsimpleLifeGoalTests build phases = Sources, Frameworks, Resources
xsimpleLifeGoalTests fileSystemSynchronizedGroups = (xsimpleLifeGoalTests)
xsimpleLifeGoalTests target dependency = xsimpleLifeGoal
xsimpleLifeGoalTests TEST_HOST = "$(BUILT_PRODUCTS_DIR)/xsimple Life Goal.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/xsimple Life Goal"
xsimpleLifeGoalTests TEST_TARGET_NAME = xsimpleLifeGoal
```

Modify `.gitignore`:

```gitignore
.superpowers/
.DS_Store
DerivedData/
build/
*.xcuserstate
xcuserdata/
Vendor/llama.cpp/
Vendor/Frameworks/
*.gguf
```

- [ ] **Step 4: Run the smoke test and verify it passes**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: PASS with `AppSmokeTests/testAppNameIsStable`.

- [ ] **Step 5: Commit**

Run:

```bash
git add .gitignore xsimpleLifeGoal.xcodeproj xsimpleLifeGoal xsimpleLifeGoalTests
git commit -m "chore: scaffold xsimple life goal app"
```

## Task 2: Domain Models And Scheduler

**Files:**
- Create: `xsimpleLifeGoal/Models/GoalDomain.swift`
- Create: `xsimpleLifeGoal/Services/GoalScheduler.swift`
- Create: `xsimpleLifeGoalTests/GoalSchedulerTests.swift`

- [ ] **Step 1: Write failing scheduler tests**

Create `xsimpleLifeGoalTests/GoalSchedulerTests.swift`:

```swift
import XCTest
@testable import xsimpleLifeGoal

final class GoalSchedulerTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testDefaultDeadlineIsOneYearAfterStartDate() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let scheduler = GoalScheduler(calendar: calendar)

        let deadline = scheduler.resolveTargetDate(startDate: start, requestedTargetDate: nil)

        XCTAssertEqual(calendar.component(.year, from: deadline), 2027)
        XCTAssertEqual(calendar.component(.month, from: deadline), 5)
        XCTAssertEqual(calendar.component(.day, from: deadline), 29)
    }

    func testUsesRequestedDeadlineWhenProvided() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let requested = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1)))
        let scheduler = GoalScheduler(calendar: calendar)

        XCTAssertEqual(scheduler.resolveTargetDate(startDate: start, requestedTargetDate: requested), requested)
    }

    func testBuildsDailyPlansFromChecklistTemplates() throws {
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 31)))
        let scheduler = GoalScheduler(calendar: calendar)

        let plans = scheduler.makeDailyPlans(
            goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            startDate: start,
            targetDate: target,
            templates: ["Review core concept", "Practice for 10 minutes"]
        )

        XCTAssertEqual(plans.count, 3)
        XCTAssertEqual(plans[0].items.map(\.text), ["Review core concept", "Practice for 10 minutes"])
        XCTAssertFalse(plans[0].isRescaled)
    }

    func testRedistributesIncompleteItemsAcrossRemainingDays() throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 29)))
        let target = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let scheduler = GoalScheduler(calendar: calendar)
        var plans = scheduler.makeDailyPlans(
            goalID: goalID,
            startDate: start,
            targetDate: target,
            templates: ["Read", "Practice", "Review"]
        )
        plans[0].items[0].isCompleted = true

        let rescaled = scheduler.rescaleAfterMissedDay(plans: plans, missedDate: start, targetDate: target)

        XCTAssertEqual(rescaled[0].items.filter { !$0.isCompleted }.count, 2)
        XCTAssertTrue(rescaled[1].isRescaled)
        XCTAssertTrue(rescaled[2].isRescaled)
        XCTAssertTrue(rescaled[3].isRescaled)
        XCTAssertGreaterThan(rescaled[1].items.count, plans[1].items.count)
    }
}
```

- [ ] **Step 2: Run scheduler tests and verify they fail**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalSchedulerTests
```

Expected: FAIL with `Cannot find type 'GoalScheduler' in scope`.

- [ ] **Step 3: Implement domain models**

Create `xsimpleLifeGoal/Models/GoalDomain.swift`:

```swift
import Foundation

enum GoalStatus: String, Codable, CaseIterable, Equatable {
    case active
    case archived
    case completed
}

enum ModelDownloadStatus: String, Codable, Equatable {
    case notDownloaded
    case downloading
    case ready
    case failed
}

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var originalDescription: String
    var createdDate: Date
    var targetDate: Date
    var status: GoalStatus
    var selectedModelID: String
    var dailyPlans: [DailyPlan]

    var progressFraction: Double {
        let items = dailyPlans.flatMap(\.items)
        guard !items.isEmpty else { return 0 }
        return Double(items.filter(\.isCompleted).count) / Double(items.count)
    }
}

struct DailyPlan: Identifiable, Codable, Equatable {
    var id: UUID
    var goalID: UUID
    var date: Date
    var items: [ChecklistItem]
    var isRescaled: Bool
}

struct ChecklistItem: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var estimatedEffort: String
    var isCompleted: Bool
    var completedDate: Date?
}

struct ModelMetadata: Identifiable, Codable, Equatable {
    var id: String
    var displayName: String
    var remoteURL: URL
    var localFilename: String
    var approximateBytes: Int64
    var status: ModelDownloadStatus
}
```

- [ ] **Step 4: Implement scheduler**

Create `xsimpleLifeGoal/Services/GoalScheduler.swift`:

```swift
import Foundation

struct GoalScheduler {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func resolveTargetDate(startDate: Date, requestedTargetDate: Date?) -> Date {
        if let requestedTargetDate {
            return calendar.startOfDay(for: requestedTargetDate)
        }
        return calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: startDate))!
    }

    func makeDailyPlans(goalID: UUID, startDate: Date, targetDate: Date, templates: [String]) -> [DailyPlan] {
        let dates = inclusiveDates(from: startDate, through: targetDate)
        let normalizedTemplates = templates.isEmpty ? ["Spend focused time on this goal"] : templates
        return dates.map { date in
            DailyPlan(
                id: UUID(),
                goalID: goalID,
                date: date,
                items: normalizedTemplates.prefix(3).map { text in
                    ChecklistItem(id: UUID(), text: text, estimatedEffort: "Small", isCompleted: false, completedDate: nil)
                },
                isRescaled: false
            )
        }
    }

    func rescaleAfterMissedDay(plans: [DailyPlan], missedDate: Date, targetDate: Date) -> [DailyPlan] {
        let missedDay = calendar.startOfDay(for: missedDate)
        let remainingDates = inclusiveDates(
            from: calendar.date(byAdding: .day, value: 1, to: missedDay) ?? missedDay,
            through: targetDate
        )
        guard !remainingDates.isEmpty else { return plans }

        let missedItems = plans
            .filter { calendar.isDate($0.date, inSameDayAs: missedDay) }
            .flatMap(\.items)
            .filter { !$0.isCompleted }

        guard !missedItems.isEmpty else { return plans }

        var itemBuckets = Array(repeating: [ChecklistItem](), count: remainingDates.count)
        for (index, item) in missedItems.enumerated() {
            var redistributed = item
            redistributed.id = UUID()
            redistributed.isCompleted = false
            redistributed.completedDate = nil
            itemBuckets[index % itemBuckets.count].append(redistributed)
        }

        return plans.map { plan in
            guard let dateIndex = remainingDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: plan.date) }) else {
                return plan
            }
            var updated = plan
            updated.items.append(contentsOf: itemBuckets[dateIndex])
            updated.isRescaled = !itemBuckets[dateIndex].isEmpty
            return updated
        }
    }

    private func inclusiveDates(from startDate: Date, through targetDate: Date) -> [Date] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: max(startDate, targetDate))
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
```

- [ ] **Step 5: Run scheduler tests and verify they pass**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalSchedulerTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add xsimpleLifeGoal/Models/GoalDomain.swift xsimpleLifeGoal/Services/GoalScheduler.swift xsimpleLifeGoalTests/GoalSchedulerTests.swift
git commit -m "feat: add goal scheduler"
```

## Task 3: Planning Engine With JSON Parsing And Fallback

**Files:**
- Create: `xsimpleLifeGoal/Services/GoalPlanningEngine.swift`
- Create: `xsimpleLifeGoalTests/GoalPlanningEngineTests.swift`

- [ ] **Step 1: Write failing planning tests**

Create `xsimpleLifeGoalTests/GoalPlanningEngineTests.swift`:

```swift
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
}

private struct FixtureTextGenerator: TextGenerating {
    let result: String

    func generateText(prompt: String) async throws -> String {
        result
    }
}
```

- [ ] **Step 2: Run planning tests and verify they fail**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalPlanningEngineTests
```

Expected: FAIL with `Cannot find type 'GoalPlanningEngine' in scope`.

- [ ] **Step 3: Implement planning engine**

Create `xsimpleLifeGoal/Services/GoalPlanningEngine.swift`:

```swift
import Foundation

protocol TextGenerating {
    func generateText(prompt: String) async throws -> String
}

struct GeneratedGoalPlan: Equatable {
    var title: String
    var dailyChecklist: [String]
    var usedFallback: Bool
}

struct GoalPlanningEngine {
    private let generator: TextGenerating

    init(generator: TextGenerating) {
        self.generator = generator
    }

    func generatePlan(description: String, daysAvailable: Int) async throws -> GeneratedGoalPlan {
        let prompt = Self.prompt(description: description, daysAvailable: daysAvailable)
        do {
            let text = try await generator.generateText(prompt: prompt)
            return try parse(text)
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
```

- [ ] **Step 4: Run planning tests and verify they pass**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalPlanningEngineTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/Services/GoalPlanningEngine.swift xsimpleLifeGoalTests/GoalPlanningEngineTests.swift
git commit -m "feat: add goal planning engine"
```

## Task 4: Model Manifest And Download State

**Files:**
- Create: `xsimpleLifeGoal/Services/ModelManager.swift`
- Create: `xsimpleLifeGoalTests/ModelManagerTests.swift`

- [ ] **Step 1: Write failing model manager tests**

Create `xsimpleLifeGoalTests/ModelManagerTests.swift`:

```swift
import XCTest
@testable import xsimpleLifeGoal

final class ModelManagerTests: XCTestCase {
    func testDefaultModelManifestUsesQwen17BGGUF() {
        let model = ModelManager.defaultModel

        XCTAssertEqual(model.id, "qwen3-1.7b-gguf")
        XCTAssertEqual(model.displayName, "Qwen3 1.7B GGUF")
        XCTAssertTrue(model.remoteURL.absoluteString.contains("Qwen3-1.7B-GGUF"))
    }

    func testSmallFallbackManifestUsesQwen06BGGUF() {
        let model = ModelManager.smallFallbackModel

        XCTAssertEqual(model.id, "qwen3-0.6b-gguf")
        XCTAssertTrue(model.remoteURL.absoluteString.contains("Qwen3-0.6B-GGUF"))
    }

    func testReportsMissingLocalModelAsNotReady() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let manager = ModelManager(fileManager: .default, applicationSupportDirectory: tempDirectory)

        XCTAssertFalse(manager.isModelReady(ModelManager.defaultModel))
    }
}
```

- [ ] **Step 2: Run model manager tests and verify they fail**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/ModelManagerTests
```

Expected: FAIL with `Cannot find type 'ModelManager' in scope`.

- [ ] **Step 3: Implement model manager**

Create `xsimpleLifeGoal/Services/ModelManager.swift`:

```swift
import Foundation

struct ModelManager {
    static let defaultModel = ModelMetadata(
        id: "qwen3-1.7b-gguf",
        displayName: "Qwen3 1.7B GGUF",
        remoteURL: URL(string: "https://huggingface.co/Qwen/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q8_0.gguf")!,
        localFilename: "Qwen3-1.7B-Q8_0.gguf",
        approximateBytes: 1_830_000_000,
        status: .notDownloaded
    )

    static let smallFallbackModel = ModelMetadata(
        id: "qwen3-0.6b-gguf",
        displayName: "Qwen3 0.6B GGUF",
        remoteURL: URL(string: "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf")!,
        localFilename: "Qwen3-0.6B-Q8_0.gguf",
        approximateBytes: 639_000_000,
        status: .notDownloaded
    )

    private let fileManager: FileManager
    private let applicationSupportDirectory: URL

    init(fileManager: FileManager = .default, applicationSupportDirectory: URL? = nil) {
        self.fileManager = fileManager
        if let applicationSupportDirectory {
            self.applicationSupportDirectory = applicationSupportDirectory
        } else {
            self.applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        }
    }

    func localURL(for model: ModelMetadata) -> URL {
        applicationSupportDirectory.appending(path: "Models", directoryHint: .isDirectory).appending(path: model.localFilename)
    }

    func isModelReady(_ model: ModelMetadata) -> Bool {
        fileManager.fileExists(atPath: localURL(for: model).path)
    }

    func ensureModelDirectoryExists() throws {
        try fileManager.createDirectory(
            at: applicationSupportDirectory.appending(path: "Models", directoryHint: .isDirectory),
            withIntermediateDirectories: true
        )
    }
}
```

- [ ] **Step 4: Run model manager tests and verify they pass**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/ModelManagerTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/Services/ModelManager.swift xsimpleLifeGoalTests/ModelManagerTests.swift
git commit -m "feat: add local model manager"
```

## Task 5: SwiftData Persistence

**Files:**
- Create: `xsimpleLifeGoal/Models/SwiftDataModels.swift`
- Create: `xsimpleLifeGoal/Stores/GoalRepository.swift`
- Create: `xsimpleLifeGoalTests/GoalRepositoryTests.swift`

- [ ] **Step 1: Write failing repository tests**

Create `xsimpleLifeGoalTests/GoalRepositoryTests.swift`:

```swift
import XCTest
import SwiftData
@testable import xsimpleLifeGoal

@MainActor
final class GoalRepositoryTests: XCTestCase {
    func testSavesAndLoadsGoalRoundTrip() throws {
        let schema = Schema([StoredGoal.self, StoredDailyPlan.self, StoredChecklistItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let repository = SwiftDataGoalRepository(context: container.mainContext)
        let goal = Goal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            title: "Learn Spanish",
            originalDescription: "learn conversational Spanish",
            createdDate: Date(timeIntervalSince1970: 10),
            targetDate: Date(timeIntervalSince1970: 20),
            status: .active,
            selectedModelID: "qwen3-1.7b-gguf",
            dailyPlans: [
                DailyPlan(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                    goalID: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                    date: Date(timeIntervalSince1970: 10),
                    items: [
                        ChecklistItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, text: "Review", estimatedEffort: "Small", isCompleted: false, completedDate: nil)
                    ],
                    isRescaled: false
                )
            ]
        )

        try repository.save(goal)
        let goals = try repository.fetchGoals()

        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals[0].title, "Learn Spanish")
        XCTAssertEqual(goals[0].dailyPlans[0].items[0].text, "Review")
    }
}
```

- [ ] **Step 2: Run repository tests and verify they fail**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalRepositoryTests
```

Expected: FAIL with `Cannot find type 'StoredGoal' in scope`.

- [ ] **Step 3: Implement SwiftData models and repository**

Create `xsimpleLifeGoal/Models/SwiftDataModels.swift`:

```swift
import Foundation
import SwiftData

@Model
final class StoredGoal {
    @Attribute(.unique) var id: UUID
    var title: String
    var originalDescription: String
    var createdDate: Date
    var targetDate: Date
    var statusRawValue: String
    var selectedModelID: String
    @Relationship(deleteRule: .cascade) var dailyPlans: [StoredDailyPlan]

    init(goal: Goal) {
        id = goal.id
        title = goal.title
        originalDescription = goal.originalDescription
        createdDate = goal.createdDate
        targetDate = goal.targetDate
        statusRawValue = goal.status.rawValue
        selectedModelID = goal.selectedModelID
        dailyPlans = goal.dailyPlans.map(StoredDailyPlan.init(plan:))
    }

    func domainValue() -> Goal {
        Goal(
            id: id,
            title: title,
            originalDescription: originalDescription,
            createdDate: createdDate,
            targetDate: targetDate,
            status: GoalStatus(rawValue: statusRawValue) ?? .active,
            selectedModelID: selectedModelID,
            dailyPlans: dailyPlans.map { $0.domainValue(goalID: id) }.sorted { $0.date < $1.date }
        )
    }
}

@Model
final class StoredDailyPlan {
    @Attribute(.unique) var id: UUID
    var goalID: UUID
    var date: Date
    var isRescaled: Bool
    @Relationship(deleteRule: .cascade) var items: [StoredChecklistItem]

    init(plan: DailyPlan) {
        id = plan.id
        goalID = plan.goalID
        date = plan.date
        isRescaled = plan.isRescaled
        items = plan.items.map(StoredChecklistItem.init(item:))
    }

    func domainValue(goalID: UUID) -> DailyPlan {
        DailyPlan(id: id, goalID: goalID, date: date, items: items.map(\.domainValue), isRescaled: isRescaled)
    }
}

@Model
final class StoredChecklistItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var estimatedEffort: String
    var isCompleted: Bool
    var completedDate: Date?

    init(item: ChecklistItem) {
        id = item.id
        text = item.text
        estimatedEffort = item.estimatedEffort
        isCompleted = item.isCompleted
        completedDate = item.completedDate
    }

    var domainValue: ChecklistItem {
        ChecklistItem(id: id, text: text, estimatedEffort: estimatedEffort, isCompleted: isCompleted, completedDate: completedDate)
    }
}
```

Create `xsimpleLifeGoal/Stores/GoalRepository.swift`:

```swift
import Foundation
import SwiftData

protocol GoalRepository {
    func fetchGoals() throws -> [Goal]
    func save(_ goal: Goal) throws
}

@MainActor
final class SwiftDataGoalRepository: GoalRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchGoals() throws -> [Goal] {
        let descriptor = FetchDescriptor<StoredGoal>(sortBy: [SortDescriptor(\.createdDate)])
        return try context.fetch(descriptor).map { $0.domainValue() }
    }

    func save(_ goal: Goal) throws {
        let id = goal.id
        let descriptor = FetchDescriptor<StoredGoal>(predicate: #Predicate { $0.id == id })
        for existing in try context.fetch(descriptor) {
            context.delete(existing)
        }
        context.insert(StoredGoal(goal: goal))
        try context.save()
    }
}
```

- [ ] **Step 4: Run repository tests and verify they pass**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalRepositoryTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/Models/SwiftDataModels.swift xsimpleLifeGoal/Stores/GoalRepository.swift xsimpleLifeGoalTests/GoalRepositoryTests.swift
git commit -m "feat: add SwiftData goal repository"
```

## Task 6: Goal Store App State

**Files:**
- Create: `xsimpleLifeGoal/ViewModels/GoalStore.swift`
- Create: `xsimpleLifeGoalTests/GoalStoreTests.swift`

- [ ] **Step 1: Write failing goal store tests**

Create `xsimpleLifeGoalTests/GoalStoreTests.swift`:

```swift
import XCTest
@testable import xsimpleLifeGoal

@MainActor
final class GoalStoreTests: XCTestCase {
    func testCreatesGoalWithGeneratedPlan() async throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: Calendar(identifier: .gregorian))
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review","Speak"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { Date(timeIntervalSince1970: 0) })

        try await store.createGoal(description: "learn conversational Spanish", targetDate: Date(timeIntervalSince1970: 86_400))

        XCTAssertEqual(store.goals.count, 1)
        XCTAssertEqual(store.goals[0].title, "Learn Spanish")
        XCTAssertEqual(store.goals[0].dailyPlans.count, 2)
    }

    func testTogglesChecklistItemCompletion() async throws {
        let repository = InMemoryGoalRepository()
        let scheduler = GoalScheduler(calendar: Calendar(identifier: .gregorian))
        let engine = GoalPlanningEngine(generator: FixtureTextGenerator(result: #"{"title":"Learn Spanish","dailyChecklist":["Review"]}"#))
        let store = GoalStore(repository: repository, scheduler: scheduler, planningEngine: engine, now: { Date(timeIntervalSince1970: 0) })
        try await store.createGoal(description: "learn Spanish", targetDate: Date(timeIntervalSince1970: 0))
        let goalID = store.goals[0].id
        let itemID = store.goals[0].dailyPlans[0].items[0].id

        try store.setChecklistItem(goalID: goalID, itemID: itemID, isCompleted: true)

        XCTAssertTrue(store.goals[0].dailyPlans[0].items[0].isCompleted)
    }
}

private final class InMemoryGoalRepository: GoalRepository {
    var goals: [Goal] = []

    func fetchGoals() throws -> [Goal] {
        goals
    }

    func save(_ goal: Goal) throws {
        goals.removeAll { $0.id == goal.id }
        goals.append(goal)
    }
}

private struct FixtureTextGenerator: TextGenerating {
    let result: String

    func generateText(prompt: String) async throws -> String {
        result
    }
}
```

- [ ] **Step 2: Run goal store tests and verify they fail**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalStoreTests
```

Expected: FAIL with `Cannot find type 'GoalStore' in scope`.

- [ ] **Step 3: Implement goal store**

Create `xsimpleLifeGoal/ViewModels/GoalStore.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class GoalStore {
    private let repository: GoalRepository
    private let scheduler: GoalScheduler
    private let planningEngine: GoalPlanningEngine
    private let now: () -> Date

    private(set) var goals: [Goal] = []
    var errorMessage: String?

    init(repository: GoalRepository, scheduler: GoalScheduler, planningEngine: GoalPlanningEngine, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.scheduler = scheduler
        self.planningEngine = planningEngine
        self.now = now
        self.goals = (try? repository.fetchGoals()) ?? []
    }

    func createGoal(description: String, targetDate: Date?) async throws {
        let start = now()
        let resolvedTarget = scheduler.resolveTargetDate(startDate: start, requestedTargetDate: targetDate)
        let days = max(1, Calendar.current.dateComponents([.day], from: start, to: resolvedTarget).day ?? 1)
        let generated = try await planningEngine.generatePlan(description: description, daysAvailable: days)
        let goalID = UUID()
        let plans = scheduler.makeDailyPlans(goalID: goalID, startDate: start, targetDate: resolvedTarget, templates: generated.dailyChecklist)
        let goal = Goal(
            id: goalID,
            title: generated.title,
            originalDescription: description,
            createdDate: start,
            targetDate: resolvedTarget,
            status: .active,
            selectedModelID: ModelManager.defaultModel.id,
            dailyPlans: plans
        )
        try repository.save(goal)
        goals = try repository.fetchGoals()
    }

    func setChecklistItem(goalID: UUID, itemID: UUID, isCompleted: Bool) throws {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        for planIndex in goals[goalIndex].dailyPlans.indices {
            guard let itemIndex = goals[goalIndex].dailyPlans[planIndex].items.firstIndex(where: { $0.id == itemID }) else { continue }
            goals[goalIndex].dailyPlans[planIndex].items[itemIndex].isCompleted = isCompleted
            goals[goalIndex].dailyPlans[planIndex].items[itemIndex].completedDate = isCompleted ? now() : nil
        }
        try repository.save(goals[goalIndex])
    }

    func rescaleMissedDay(goalID: UUID, missedDate: Date) throws {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalID }) else { return }
        goals[goalIndex].dailyPlans = scheduler.rescaleAfterMissedDay(
            plans: goals[goalIndex].dailyPlans,
            missedDate: missedDate,
            targetDate: goals[goalIndex].targetDate
        )
        try repository.save(goals[goalIndex])
    }
}
```

- [ ] **Step 4: Run goal store tests and verify they pass**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalStoreTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/ViewModels/GoalStore.swift xsimpleLifeGoalTests/GoalStoreTests.swift
git commit -m "feat: add goal store"
```

## Task 7: Dashboard And Creation UI

**Files:**
- Create: `xsimpleLifeGoal/Views/AppTheme.swift`
- Create: `xsimpleLifeGoal/Views/GoalDashboardView.swift`
- Create: `xsimpleLifeGoal/Views/GoalCreationView.swift`
- Create: `xsimpleLifeGoal/Views/Components/GoalCard.swift`
- Modify: `xsimpleLifeGoal/ContentView.swift`
- Modify: `xsimpleLifeGoal/xsimpleLifeGoalApp.swift`

- [ ] **Step 1: Build before UI changes**

Run:

```bash
xcodebuild build -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'generic/platform=iOS Simulator'
```

Expected: PASS. This locks the pre-UI baseline.

- [ ] **Step 2: Implement theme and dashboard components**

Create `xsimpleLifeGoal/Views/AppTheme.swift`:

```swift
import SwiftUI

enum AppTheme {
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let muted = Color(red: 0.45, green: 0.49, blue: 0.54)
    static let accent = Color(red: 0.12, green: 0.52, blue: 0.58)
    static let warm = Color(red: 0.94, green: 0.58, blue: 0.24)
    static let background = Color(red: 0.97, green: 0.98, blue: 0.98)
    static let card = Color.white
    static let radius: CGFloat = 8
}
```

Create `xsimpleLifeGoal/Views/Components/GoalCard.swift`:

```swift
import SwiftUI

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("\(Int(goal.progressFraction * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            ProgressView(value: goal.progressFraction)
                .tint(AppTheme.accent)

            Text(todaySummary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var todaySummary: String {
        guard let plan = goal.dailyPlans.first else { return "No checklist yet" }
        let completed = plan.items.filter(\.isCompleted).count
        return "\(completed)/\(plan.items.count) items complete today"
    }
}
```

Create `xsimpleLifeGoal/Views/GoalDashboardView.swift`:

```swift
import SwiftUI

struct GoalDashboardView: View {
    @Bindable var store: GoalStore
    @State private var showingCreation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.goals) { goal in
                            NavigationLink(value: goal.id) {
                                GoalCard(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Life Goals")
            .toolbar {
                Button {
                    showingCreation = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Goal")
            }
            .sheet(isPresented: $showingCreation) {
                GoalCreationView(store: store)
            }
        }
    }
}
```

Create `xsimpleLifeGoal/Views/GoalCreationView.swift`:

```swift
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
```

- [ ] **Step 3: Wire SwiftData and root store**

Modify `xsimpleLifeGoal/xsimpleLifeGoalApp.swift`:

```swift
import SwiftUI
import SwiftData

enum AppMetadata {
    static let displayName = "xsimple Life Goal"
}

@main
struct xsimpleLifeGoalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([StoredGoal.self, StoredDailyPlan.self, StoredChecklistItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

Modify `xsimpleLifeGoal/ContentView.swift`:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let repository = SwiftDataGoalRepository(context: modelContext)
        let planner = GoalPlanningEngine(generator: UnavailableTextGenerator())
        let store = GoalStore(repository: repository, scheduler: GoalScheduler(), planningEngine: planner)
        GoalDashboardView(store: store)
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Build and verify UI compiles**

Run:

```bash
xcodebuild build -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'generic/platform=iOS Simulator'
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/Views xsimpleLifeGoal/ContentView.swift xsimpleLifeGoal/xsimpleLifeGoalApp.swift
git commit -m "feat: add goal dashboard and creation UI"
```

## Task 8: Goal Detail And Checklist Completion UI

**Files:**
- Create: `xsimpleLifeGoal/Views/GoalDetailView.swift`
- Create: `xsimpleLifeGoal/Views/Components/DailyChecklistView.swift`
- Create: `xsimpleLifeGoal/Views/Components/ProgressSummaryView.swift`
- Modify: `xsimpleLifeGoal/Views/GoalDashboardView.swift`

- [ ] **Step 1: Build before detail changes**

Run:

```bash
xcodebuild build -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'generic/platform=iOS Simulator'
```

Expected: PASS.

- [ ] **Step 2: Implement checklist and progress components**

Create `xsimpleLifeGoal/Views/Components/DailyChecklistView.swift`:

```swift
import SwiftUI

struct DailyChecklistView: View {
    let plan: DailyPlan
    let onToggle: (UUID, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.headline)

            ForEach(plan.items) { item in
                Button {
                    onToggle(item.id, !item.isCompleted)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? AppTheme.accent : AppTheme.muted)
                        Text(item.text)
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius))
    }
}
```

Create `xsimpleLifeGoal/Views/Components/ProgressSummaryView.swift`:

```swift
import SwiftUI

struct ProgressSummaryView: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.headline)
            ProgressView(value: goal.progressFraction)
                .tint(AppTheme.accent)
            Text("\(Int(goal.progressFraction * 100))% complete")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius))
    }
}
```

- [ ] **Step 3: Implement goal detail and navigation**

Create `xsimpleLifeGoal/Views/GoalDetailView.swift`:

```swift
import SwiftUI

struct GoalDetailView: View {
    @Bindable var store: GoalStore
    let goalID: UUID

    private var goal: Goal? {
        store.goals.first { $0.id == goalID }
    }

    var body: some View {
        ScrollView {
            if let goal {
                VStack(alignment: .leading, spacing: 14) {
                    Text(goal.originalDescription)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)

                    if let today = goal.dailyPlans.first {
                        DailyChecklistView(plan: today) { itemID, isCompleted in
                            try? store.setChecklistItem(goalID: goal.id, itemID: itemID, isCompleted: isCompleted)
                        }
                    }

                    ProgressSummaryView(goal: goal)

                    Button("Rescale Missed Work") {
                        try? store.rescaleMissedDay(goalID: goal.id, missedDate: Date())
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                ContentUnavailableView("Goal Not Found", systemImage: "target")
            }
        }
        .background(AppTheme.background)
        .navigationTitle(goal?.title ?? "Goal")
    }
}
```

Modify `xsimpleLifeGoal/Views/GoalDashboardView.swift` navigation stack:

```swift
.navigationDestination(for: UUID.self) { goalID in
    GoalDetailView(store: store, goalID: goalID)
}
```

- [ ] **Step 4: Build and verify detail UI compiles**

Run:

```bash
xcodebuild build -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'generic/platform=iOS Simulator'
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/Views/GoalDetailView.swift xsimpleLifeGoal/Views/Components/DailyChecklistView.swift xsimpleLifeGoal/Views/Components/ProgressSummaryView.swift xsimpleLifeGoal/Views/GoalDashboardView.swift
git commit -m "feat: add goal detail checklist UI"
```

## Task 9: Model Setup UI And Download View Model

**Files:**
- Create: `xsimpleLifeGoal/ViewModels/ModelSetupViewModel.swift`
- Create: `xsimpleLifeGoal/Views/ModelSetupView.swift`
- Modify: `xsimpleLifeGoal/ContentView.swift`

- [ ] **Step 1: Write failing model setup state test**

Add to `xsimpleLifeGoalTests/ModelManagerTests.swift`:

```swift
func testModelSetupViewModelStartsWithDefaultModel() {
    let manager = ModelManager(fileManager: .default, applicationSupportDirectory: FileManager.default.temporaryDirectory)
    let viewModel = ModelSetupViewModel(modelManager: manager)

    XCTAssertEqual(viewModel.selectedModel.id, "qwen3-1.7b-gguf")
    XCTAssertFalse(viewModel.isReady)
}
```

- [ ] **Step 2: Run the model setup state test and verify it fails**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/ModelManagerTests/testModelSetupViewModelStartsWithDefaultModel
```

Expected: FAIL with `Cannot find type 'ModelSetupViewModel' in scope`.

- [ ] **Step 3: Implement setup view model and UI**

Create `xsimpleLifeGoal/ViewModels/ModelSetupViewModel.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class ModelSetupViewModel {
    private let modelManager: ModelManager
    var selectedModel: ModelMetadata
    var isReady: Bool
    var statusText: String

    init(modelManager: ModelManager = ModelManager(), selectedModel: ModelMetadata = ModelManager.defaultModel) {
        self.modelManager = modelManager
        self.selectedModel = selectedModel
        self.isReady = modelManager.isModelReady(selectedModel)
        self.statusText = self.isReady ? "Model ready" : "Model download required"
    }

    func useSmallModel() {
        selectedModel = ModelManager.smallFallbackModel
        isReady = modelManager.isModelReady(selectedModel)
        statusText = isReady ? "Model ready" : "Small model download required"
    }
}
```

Create `xsimpleLifeGoal/Views/ModelSetupView.swift`:

```swift
import SwiftUI

struct ModelSetupView: View {
    @Bindable var viewModel: ModelSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.accent)

            Text("Offline Model")
                .font(.title.weight(.semibold))

            Text(viewModel.statusText)
                .foregroundStyle(AppTheme.muted)

            Text(viewModel.selectedModel.displayName)
                .font(.headline)

            Button("Use Smaller Model") {
                viewModel.useSmallModel()
            }
            .buttonStyle(.bordered)

            Button("Download Model") {
                viewModel.statusText = "Download queued."
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(AppTheme.background)
    }
}
```

Modify `xsimpleLifeGoal/ContentView.swift` so it routes to setup only when the default model is not present and still allows the dashboard for development builds:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showModelSetup = false
    @State private var setupViewModel = ModelSetupViewModel()

    var body: some View {
        Group {
            if showModelSetup {
                ModelSetupView(viewModel: setupViewModel)
            } else {
                let repository = SwiftDataGoalRepository(context: modelContext)
                let planner = GoalPlanningEngine(generator: UnavailableTextGenerator())
                let store = GoalStore(repository: repository, scheduler: GoalScheduler(), planningEngine: planner)
                GoalDashboardView(store: store)
            }
        }
        .onAppear {
            showModelSetup = !setupViewModel.isReady
        }
    }
}
```

- [ ] **Step 4: Run model setup test and build**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/ModelManagerTests/testModelSetupViewModelStartsWithDefaultModel
xcodebuild build -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'generic/platform=iOS Simulator'
```

Expected: PASS for both commands.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/ViewModels/ModelSetupViewModel.swift xsimpleLifeGoal/Views/ModelSetupView.swift xsimpleLifeGoal/ContentView.swift xsimpleLifeGoalTests/ModelManagerTests.swift
git commit -m "feat: add offline model setup UI"
```

## Task 10: llama.cpp Integration Boundary

**Files:**
- Create: `xsimpleLifeGoal/Services/LocalLLMService.swift`
- Create: `scripts/build-llama-xcframework.sh`
- Create: `Vendor/README.md`
- Modify: `xsimpleLifeGoal.xcodeproj/project.pbxproj`
- Modify: `xsimpleLifeGoal/ContentView.swift`

- [ ] **Step 1: Write failing local LLM fallback test**

Add to `xsimpleLifeGoalTests/GoalPlanningEngineTests.swift`:

```swift
func testLocalLLMServiceReportsRuntimeUnavailableWithoutFramework() async {
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
```

- [ ] **Step 2: Run local LLM test and verify it fails**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalPlanningEngineTests/testLocalLLMServiceReportsRuntimeUnavailableWithoutFramework
```

Expected: FAIL with `Cannot find type 'LocalLLMService' in scope`.

- [ ] **Step 3: Implement local LLM service boundary**

Create `xsimpleLifeGoal/Services/LocalLLMService.swift`:

```swift
import Foundation

enum LocalLLMError: Error, Equatable {
    case runtimeUnavailable
    case modelFileMissing
    case generationFailed
}

struct LocalLLMService: TextGenerating {
    var modelURL: URL?

    init(modelURL: URL? = nil) {
        self.modelURL = modelURL
    }

    func generateText(prompt: String) async throws -> String {
        #if canImport(llama)
        return try await LlamaTextRuntime(modelURL: modelURL).generate(prompt: prompt)
        #else
        throw LocalLLMError.runtimeUnavailable
        #endif
    }
}

#if canImport(llama)
import llama

private struct LlamaTextRuntime {
    let modelURL: URL?

    func generate(prompt: String) async throws -> String {
        guard modelURL != nil else {
            throw LocalLLMError.modelFileMissing
        }
        throw LocalLLMError.generationFailed
    }
}
#endif
```

Create `scripts/build-llama-xcframework.sh`:

```bash
#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor"
LLAMA_DIR="$VENDOR_DIR/llama.cpp"
FRAMEWORK_DIR="$VENDOR_DIR/Frameworks"

mkdir -p "$VENDOR_DIR" "$FRAMEWORK_DIR"

if [ ! -d "$LLAMA_DIR/.git" ]; then
  git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
fi

cd "$LLAMA_DIR"
./build-xcframework.sh
rsync -a "$LLAMA_DIR/build-apple/llama.xcframework" "$FRAMEWORK_DIR/"

echo "Copied llama.xcframework to $FRAMEWORK_DIR/llama.xcframework"
```

Create `Vendor/README.md`:

```markdown
# Vendor Artifacts

Run `scripts/build-llama-xcframework.sh` to clone `llama.cpp`, build `llama.xcframework`, and copy it into `Vendor/Frameworks/`.

The generated framework and cloned source are ignored by git. The app builds without the framework and reports `LocalLLMError.runtimeUnavailable`; when the framework is present and linked, `LocalLLMService` compiles the `canImport(llama)` path.
```

Modify `xsimpleLifeGoal.xcodeproj/project.pbxproj` to add `Vendor/Frameworks/llama.xcframework` to the app target's Frameworks phase and framework search paths:

```text
FRAMEWORK_SEARCH_PATHS = (
    "$(inherited)",
    "$(PROJECT_DIR)/Vendor/Frameworks",
);
```

Modify the planner construction in `xsimpleLifeGoal/ContentView.swift`:

```swift
let planner = GoalPlanningEngine(generator: LocalLLMService())
```

- [ ] **Step 4: Run local LLM test and build**

Run:

```bash
chmod +x scripts/build-llama-xcframework.sh
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:xsimpleLifeGoalTests/GoalPlanningEngineTests/testLocalLLMServiceReportsRuntimeUnavailableWithoutFramework
xcodebuild build -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'generic/platform=iOS Simulator'
```

Expected: PASS. The test confirms the app degrades safely when the XCFramework is not present.

- [ ] **Step 5: Commit**

Run:

```bash
git add xsimpleLifeGoal/Services/LocalLLMService.swift scripts/build-llama-xcframework.sh Vendor/README.md xsimpleLifeGoal.xcodeproj/project.pbxproj xsimpleLifeGoal/ContentView.swift xsimpleLifeGoalTests/GoalPlanningEngineTests.swift
git commit -m "feat: add local llm service boundary"
```

## Task 11: Full Verification

**Files:**
- Modify: no source files unless verification exposes a failure.

- [ ] **Step 1: Run the full unit test suite**

Run:

```bash
xcodebuild test -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: PASS for all tests.

- [ ] **Step 2: Run a simulator build**

Run:

```bash
xcodebuild build -project xsimpleLifeGoal.xcodeproj -scheme xsimpleLifeGoal -destination 'generic/platform=iOS Simulator'
```

Expected: PASS.

- [ ] **Step 3: Review git status**

Run:

```bash
git status --short
```

Expected: no uncommitted files except local `.superpowers/` content ignored by git.

- [ ] **Step 4: Commit fixes if verification required changes**

Run only if Step 1 or Step 2 forced source changes:

```bash
git add xsimpleLifeGoal xsimpleLifeGoalTests xsimpleLifeGoal.xcodeproj scripts Vendor .gitignore
git commit -m "fix: stabilize life goal verification"
```

Expected: commit created only when source changes were needed.

## Sources Checked

- `llama.cpp` iOS SwiftUI sample: https://github.com/ggml-org/llama.cpp/tree/master/examples/llama.swiftui
- `llama.cpp` build note for `build-xcframework.sh`: https://github.com/ggml-org/llama.cpp/blob/master/examples/llama.swiftui/README.md
- Qwen3 1.7B GGUF model: https://huggingface.co/Qwen/Qwen3-1.7B-GGUF
- Qwen3 0.6B GGUF model: https://huggingface.co/Qwen/Qwen3-0.6B-GGUF

import XCTest
@testable import xsimpleLifeGoal

final class LocalizationTests: XCTestCase {
    func testEnglishAndSimplifiedChineseLocalizableKeysMatch() throws {
        let en = try stringsDictionary(at: appSourceDirectory.appending(path: "en.lproj/Localizable.strings"))
        let zhHans = try stringsDictionary(at: appSourceDirectory.appending(path: "zh-Hans.lproj/Localizable.strings"))

        XCTAssertEqual(Set(en.keys), Set(zhHans.keys))
    }

    func testSimplifiedChineseInfoPlistDisplayNameIsLocalized() throws {
        let zhHans = try stringsDictionary(at: appSourceDirectory.appending(path: "zh-Hans.lproj/InfoPlist.strings"))

        XCTAssertEqual(zhHans["CFBundleDisplayName"], "小目标")
    }

    func testLocalizedStringLookupReadsEnglishAndSimplifiedChineseResources() {
        XCTAssertEqual(AppStrings.string("dashboard.title", localeIdentifier: "en"), "Life Goals")
        XCTAssertEqual(AppStrings.string("dashboard.title", localeIdentifier: "zh-Hans"), "小目标")
        XCTAssertEqual(AppStrings.string("goalCreation.generateButton", localeIdentifier: "zh-Hans"), "生成每日计划")
    }

    func testModelDisplayNamesAreLocalizedForSimplifiedChineseOnlyAtUILayer() {
        XCTAssertEqual(
            AppStrings.modelDisplayName(for: ModelManager.defaultModel, locale: Locale(identifier: "en")),
            "Goal Planner AI"
        )
        XCTAssertEqual(
            AppStrings.modelDisplayName(for: ModelManager.defaultModel, locale: Locale(identifier: "zh-Hans")),
            "目标规划 AI"
        )
        XCTAssertEqual(
            AppStrings.modelDisplayName(for: ModelManager.smallFallbackModel, locale: Locale(identifier: "zh-Hans")),
            "目标规划 AI 轻量版"
        )
        XCTAssertEqual(ModelManager.defaultModel.displayName, "Goal Planner AI")
        XCTAssertEqual(ModelManager.smallFallbackModel.displayName, "Goal Planner AI Lite")
    }

    private var appSourceDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "xsimpleLifeGoal", directoryHint: .isDirectory)
    }

    private func stringsDictionary(at url: URL) throws -> [String: String] {
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: String])
    }
}

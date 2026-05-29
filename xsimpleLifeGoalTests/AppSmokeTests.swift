import XCTest
@testable import xsimpleLifeGoal

final class AppSmokeTests: XCTestCase {
    func testAppNameIsStable() {
        XCTAssertEqual(AppMetadata.displayName, "xsimple Life Goal")
    }
}

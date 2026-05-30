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

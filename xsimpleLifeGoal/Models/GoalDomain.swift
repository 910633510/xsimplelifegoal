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

    func dailyPlan(on date: Date, calendar: Calendar) -> DailyPlan? {
        dailyPlans.first { calendar.isDate($0.date, inSameDayAs: date) }
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

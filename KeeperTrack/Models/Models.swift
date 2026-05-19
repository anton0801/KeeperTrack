import Foundation
import SwiftUI

// MARK: - Keeper Profile
struct Keeper: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var team: String
    var notes: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var saveRate: Double {
        // computed from associated penalties via store
        0
    }
}

// MARK: - Penalty Record
struct PenaltyRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var keeperID: UUID
    var date: Date = Date()
    var shotZone: PenaltyZone
    var diveDirection: DiveDirection
    var outcome: PenaltyOutcome
    var notes: String = ""
    var sessionTag: String = ""
}

// MARK: - Training Task
struct TrainingTask: Identifiable, Codable {
    var id: UUID = UUID()
    var keeperID: UUID?
    var title: String
    var notes: String = ""
    var dueDate: Date?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var priority: TaskPriority = .medium

    enum TaskPriority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color {
            switch self {
            case .low: return .chartNeutral
            case .medium: return .accentOrange
            case .high: return .chartMiss
            }
        }
    }
}

// MARK: - Notification Setting
struct NotificationSetting: Codable {
    var isEnabled: Bool = false
    var hour: Int = 9
    var minute: Int = 0
    var frequency: NotificationFrequency = .daily

    enum NotificationFrequency: String, CaseIterable, Codable {
        case daily = "Daily"
        case weekdays = "Weekdays"
        case weekly = "Weekly"
    }
}

// MARK: - Analytics Summary
struct AnalyticsSummary {
    let totalPenalties: Int
    let saves: Int
    let scored: Int
    let missed: Int
    let leftDiveCount: Int
    let centerDiveCount: Int
    let rightDiveCount: Int
    let zoneHeatData: [PenaltyZone: Int]
    let saveRateByZone: [PenaltyZone: Double]
    let weeklyData: [WeeklyPoint]

    var saveRate: Double {
        guard totalPenalties > 0 else { return 0 }
        return Double(saves) / Double(totalPenalties) * 100
    }

    struct WeeklyPoint: Identifiable {
        let id = UUID()
        let label: String
        let saves: Int
        let total: Int
        var rate: Double { total > 0 ? Double(saves) / Double(total) * 100 : 0 }
    }
}

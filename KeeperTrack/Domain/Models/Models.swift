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


class KeeperFault: Error, CustomStringConvertible {
    let code: String
    let context: String?
    
    init(code: String, context: String? = nil) {
        self.code = code
        self.context = context
    }
    
    var description: String {
        if let ctx = context {
            return "\(String(describing: type(of: self)))[\(code): \(ctx)]"
        }
        return "\(String(describing: type(of: self)))[\(code)]"
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

final class AttributionFault: KeeperFault {
    init(reason: String) {
        super.init(code: "ATTRIBUTION", context: reason)
    }
}

final class ValidationFault: KeeperFault {
    init(reason: String) {
        super.init(code: "VALIDATION", context: reason)
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

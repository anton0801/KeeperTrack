import Foundation
import SwiftUI

struct VaultRecord: Codable {
    let keys: [String: String]
    let tags: [String: String]
    let ledgerURL: String?
    let ledgerMode: String?
    let untouched: Bool
    let consentGranted: Bool
    let consentRevoked: Bool
    let consentStampedAt: Date?
}

enum KeeperOutcome {
    case standingGuard
    case requestConsent
    case openLedger
    case bouncedToHall
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

final class NetworkFault: KeeperFault {
    let httpCode: Int?
    let retryAfter: TimeInterval?
    
    init(reason: String, httpCode: Int? = nil, retryAfter: TimeInterval? = nil) {
        self.httpCode = httpCode
        self.retryAfter = retryAfter
        super.init(code: "NETWORK", context: reason)
    }
}

final class ServerRejection: KeeperFault {
    let httpCode: Int
    
    init(httpCode: Int, reason: String) {
        self.httpCode = httpCode
        super.init(code: "SERVER_REJECTION", context: reason)
    }
}

final class ParsingFault: KeeperFault {
    init(stage: String) {
        super.init(code: "PARSING", context: stage)
    }
}

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

final class LifecycleFault: KeeperFault {
    init(reason: String) {
        super.init(code: "LIFECYCLE", context: reason)
    }
}

struct VaultKey {
    static let ledgerURL = "kt_ledger_url"
    static let ledgerMode = "kt_ledger_mode"
    static let primed = "kt_primed"
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

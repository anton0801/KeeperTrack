import Foundation

@MainActor
final class KeeperContext {
    
    var keys: [String: String] = [:]
    var tags: [String: String] = [:]
    var ledgerURL: String? = nil
    var ledgerMode: String? = nil
    var untouched: Bool = true
    var locked: Bool = false
    var organicHandled: Bool = false
    var consentGranted: Bool = false
    var consentRevoked: Bool = false
    var consentStampedAt: Date? = nil
    
    let services: KeeperServiceHolder
    
    init(services: KeeperServiceHolder) {
        self.services = services
    }
    
    var keysReady: Bool { !keys.isEmpty }
    var organicSource: Bool { keys["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentGranted && !consentRevoked else { return false }
        if let date = consentStampedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    func hydrate(from record: VaultRecord) {
        keys = record.keys
        tags = record.tags
        ledgerURL = record.ledgerURL
        ledgerMode = record.ledgerMode
        untouched = record.untouched
        consentGranted = record.consentGranted
        consentRevoked = record.consentRevoked
        consentStampedAt = record.consentStampedAt
    }
    
    func freeze() -> VaultRecord {
        VaultRecord(
            keys: keys, tags: tags,
            ledgerURL: ledgerURL, ledgerMode: ledgerMode,
            untouched: untouched,
            consentGranted: consentGranted, consentRevoked: consentRevoked,
            consentStampedAt: consentStampedAt
        )
    }
}

@MainActor
protocol KeeperPhase {
    var label: String { get }
    
    func enter(context: KeeperContext) async -> PhaseTransition
}

enum PhaseTransition {
    case advance(AnyKeeperPhase)
    case settle(KeeperOutcome)
    case halt(KeeperFault)
}

@MainActor
struct AnyKeeperPhase: KeeperPhase {
    
    let label: String
    private let _enter: (KeeperContext) async -> PhaseTransition
    
    init<Phase: KeeperPhase>(_ phase: Phase) {
        self.label = phase.label
        self._enter = phase.enter
    }
    
    func enter(context: KeeperContext) async -> PhaseTransition {
        await _enter(context)
    }
}

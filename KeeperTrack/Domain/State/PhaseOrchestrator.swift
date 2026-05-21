import Foundation
import Combine

@MainActor
final class PhaseOrchestrator {
    
    let context: KeeperContext
    
    private let outcomeSubject = PassthroughSubject<KeeperOutcome, Never>()
    var outcomePublisher: AnyPublisher<KeeperOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    private let maxPhaseDepth = 12
    
    init(services: KeeperServiceHolder = KeeperServiceHolder()) {
        self.context = KeeperContext(services: services)
    }
    
    func warmUp() {
        let record = context.services.keeperVault().unlock()
        context.hydrate(from: record)
    }
    
    func ingestKeys(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        context.keys = mapped
        let record = context.freeze()
        context.services.keeperVault().stash(record)
    }
    
    func ingestTags(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        context.tags = mapped
        let record = context.freeze()
        context.services.keeperVault().stash(record)
    }
    
    func ignite() async {
        guard !sequenceCompleted else { return }
        
        // Стартовая phase
        var currentPhase: AnyKeeperPhase = AnyKeeperPhase(PushPerchPhase())
        var depth = 0
        
        while depth < maxPhaseDepth {
            depth += 1
            
            if sequenceCompleted { return }
            
            let transition = await currentPhase.enter(context: context)
            
            switch transition {
            case .advance(let nextPhase):
                currentPhase = nextPhase
                continue
                
            case .settle(let outcome):
                if case .standingGuard = outcome {
                    return
                }
                sequenceCompleted = true
                outcomeSubject.send(outcome)
                return
                
            case .halt(let fault):
                sequenceCompleted = true
                outcomeSubject.send(.bouncedToHall)
                return
            }
        }
        
        sequenceCompleted = true
        outcomeSubject.send(.bouncedToHall)
    }
    
    func acceptConsent(call: @escaping () -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            
            let priorGranted = self.context.consentGranted
            let priorRevoked = self.context.consentRevoked
            
            var grantedFlag: Bool = false
            
            for await granted in self.context.services.consentSummoner().summon() {
                grantedFlag = granted
            }
            
            let now = Date()
            
            if grantedFlag {
                self.context.consentGranted = true
                self.context.consentRevoked = false
                self.context.consentStampedAt = now
                self.context.services.consentSummoner().ringPushBell()
            } else {
                self.context.consentGranted = false
                self.context.consentRevoked = true
                self.context.consentStampedAt = now
            }
            
            _ = priorGranted
            _ = priorRevoked
            
            let record = self.context.freeze()
            self.context.services.keeperVault().stash(record)
            self.outcomeSubject.send(.openLedger)
            call()
        }
    }
    
    func deferConsent() {
        let now = Date()
        context.consentStampedAt = now
        let record = context.freeze()
        context.services.keeperVault().stash(record)
        outcomeSubject.send(.openLedger)
    }
    
    func reportLifecycleExpired() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
}

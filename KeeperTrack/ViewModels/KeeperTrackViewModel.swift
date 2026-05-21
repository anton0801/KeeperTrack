import Foundation
import Combine

@MainActor
final class KeeperTrackViewModel: ObservableObject {
    
    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let orchestrator: PhaseOrchestrator
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.orchestrator = PhaseOrchestrator()
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func wireUp() {
        orchestrator.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func boot() {
        orchestrator.warmUp()
        armDeadline()
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            orchestrator.ingestKeys(data)
            await orchestrator.ignite()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        orchestrator.ingestTags(data)
    }
    
    func acceptConsent() {
        orchestrator.acceptConsent {
            self.showPermissionPrompt = false
        }
        
    }
    
    func skipConsent() {
        orchestrator.deferConsent()
        showPermissionPrompt = false
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: KeeperOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .standingGuard:
            break
        case .requestConsent:
            showPermissionPrompt = true
        case .openLedger:
            navigateToWeb = true
        case .bouncedToHall:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.orchestrator.reportLifecycleExpired()
            if shouldFire {
                self.handleOutcome(.bouncedToHall)
            }
        }
    }
}

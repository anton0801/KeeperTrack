import Foundation
import AppsFlyerLib

@MainActor
struct PushPerchPhase: KeeperPhase {
    let label = "pushPerch"
    
    func enter(context: KeeperContext) async -> PhaseTransition {
        guard let pushURL = UserDefaults.standard.string(forKey: VaultKey.pushURL),
              !pushURL.isEmpty else {
            return .advance(AnyKeeperPhase(VoltageSentryPhase()))
        }
        
        let needsConsent = context.consentRipe
        
        context.ledgerURL = pushURL
        context.ledgerMode = "Active"
        context.untouched = false
        context.locked = true
        
        let vault = context.services.keeperVault()
        vault.stash(context.freeze())
        vault.stashLedger(url: pushURL, mode: "Active")
        vault.markPrimed()
        UserDefaults.standard.removeObject(forKey: VaultKey.pushURL)
        
        return .settle(needsConsent ? .requestConsent : .openLedger)
    }
}

@MainActor
struct VoltageSentryPhase: KeeperPhase {
    let label = "voltageSentry"
    
    func enter(context: KeeperContext) async -> PhaseTransition {
        guard context.keysReady else {
            return .settle(.standingGuard)
        }
        
        do {
            let valid = try await context.services.voltageSentry().sentryCheck()
            
            if !valid {
                return .halt(ValidationFault(reason: "verdict false"))
            }
            
            if context.organicSource && context.untouched && !context.organicHandled {
                return .advance(AnyKeeperPhase(OrganicRetrievalPhase()))
            }
            return .advance(AnyKeeperPhase(LedgerLocationPhase()))
        } catch let fault as KeeperFault {
            return .halt(fault)
        } catch {
            return .halt(ValidationFault(reason: "\(error)"))
        }
    }
}

@MainActor
struct OrganicRetrievalPhase: KeeperPhase {
    let label = "organicRetrieval"
    
    func enter(context: KeeperContext) async -> PhaseTransition {
        context.organicHandled = true
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !context.locked else {
            return .advance(AnyKeeperPhase(LedgerLocationPhase()))
        }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await context.services.attributionRetriever().retrieve(deviceID: deviceID)
            
            for (k, v) in context.tags {
                if fetched[k] == nil {
                    fetched[k] = v
                }
            }
            
            let mapped = fetched.mapValues { "\($0)" }
            context.keys = mapped
            
            let vault = context.services.keeperVault()
            vault.stash(context.freeze())
        } catch {
        }
        
        return .advance(AnyKeeperPhase(LedgerLocationPhase()))
    }
}

@MainActor
struct LedgerLocationPhase: KeeperPhase {
    let label = "ledgerLocation"
    
    func enter(context: KeeperContext) async -> PhaseTransition {
        guard context.keysReady else {
            return .settle(.standingGuard)
        }
        
        let seed = context.keys.mapValues { $0 as Any }
        
        do {
            let url = try await context.services.ledgerLocator().locate(seed: seed)
            
            let needsConsent = context.consentRipe
            
            context.ledgerURL = url
            context.ledgerMode = "Active"
            context.untouched = false
            context.locked = true
            
            let vault = context.services.keeperVault()
            vault.stash(context.freeze())
            vault.stashLedger(url: url, mode: "Active")
            vault.markPrimed()
            UserDefaults.standard.removeObject(forKey: VaultKey.pushURL)
            
            return .settle(needsConsent ? .requestConsent : .openLedger)
        } catch let fault as KeeperFault {
            return .halt(fault)
        } catch {
            return .halt(NetworkFault(reason: "\(error)"))
        }
    }
}

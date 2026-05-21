import Foundation
import Combine


final class KeyWeaver: NSObject {
    
    var relayKeys: (([AnyHashable: Any]) -> Void)?
    var relayTags: (([AnyHashable: Any]) -> Void)?
    
    private var keysBuffer: [AnyHashable: Any] = [:]
    private var tagsBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    func acceptKeys(_ data: [AnyHashable: Any]) {
        keysBuffer = data
        scheduleFuse()
        if !tagsBuffer.isEmpty { performFuse() }
    }
    
    func acceptTags(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: VaultKey.primed) else { return }
        tagsBuffer = data
        relayTags?(data)
        fuseTimer?.invalidate()
        if !keysBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = keysBuffer
        for (k, v) in tagsBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        relayKeys?(combined)
    }
}

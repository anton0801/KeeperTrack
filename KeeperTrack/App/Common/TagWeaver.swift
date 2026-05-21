import Foundation
import Combine

final class TagWeaver: NSObject {
    
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(payload) else { return }
        UserDefaults.standard.set(url, forKey: VaultKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}

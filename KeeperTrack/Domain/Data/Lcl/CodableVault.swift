import Foundation

protocol KeeperVault {
    func stash(_ record: VaultRecord)
    func stashLedger(url: String, mode: String)
    func markPrimed()
    func unlock() -> VaultRecord
}

final class CodableKeeperVault: KeeperVault {
    
    private let fm = FileManager.default
    private let vaultDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.vaultDir = docs.appendingPathComponent("KeeperVault", isDirectory: true)
        if !fm.fileExists(atPath: vaultDir.path) {
            try? fm.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        }
        
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: VaultConstants.suiteVault) ?? .standard
    }
    
    private var fileURL: URL {
        vaultDir.appendingPathComponent(VaultConstants.vaultFile)
    }
    
    // MARK: - Stash
    
    func stash(_ record: VaultRecord) {
        let veiled = VeiledRecord(
            keys: veilDict(record.keys),
            tags: veilDict(record.tags),
            ledgerURL: record.ledgerURL,
            ledgerMode: record.ledgerMode,
            untouched: record.untouched,
            consentGranted: record.consentGranted,
            consentRevoked: record.consentRevoked,
            consentStampedAt: record.consentStampedAt
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        
        do {
            let data = try encoder.encode(veiled)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("\(VaultConstants.logKey) Stash failed: \(error)")
        }
    }
    
    func stashLedger(url: String, mode: String) {
        suiteStore.set(url, forKey: VaultKey.ledgerURL)
        homeStore.set(url, forKey: VaultKey.ledgerURL)
        suiteStore.set(mode, forKey: VaultKey.ledgerMode)
    }
    
    func markPrimed() {
        suiteStore.set(true, forKey: VaultKey.primed)
        homeStore.set(true, forKey: VaultKey.primed)
    }
    
    // MARK: - Unlock
    
    func unlock() -> VaultRecord {
        guard fm.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return fallback()
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        do {
            let veiled = try decoder.decode(VeiledRecord.self, from: data)
            return VaultRecord(
                keys: unveilDict(veiled.keys),
                tags: unveilDict(veiled.tags),
                ledgerURL: veiled.ledgerURL,
                ledgerMode: veiled.ledgerMode,
                untouched: veiled.untouched,
                consentGranted: veiled.consentGranted,
                consentRevoked: veiled.consentRevoked,
                consentStampedAt: veiled.consentStampedAt
            )
        } catch {
            return fallback()
        }
    }
    
    private func fallback() -> VaultRecord {
        let ledgerURL = homeStore.string(forKey: VaultKey.ledgerURL)
            ?? suiteStore.string(forKey: VaultKey.ledgerURL)
        let ledgerMode = suiteStore.string(forKey: VaultKey.ledgerMode)
        let primed = suiteStore.bool(forKey: VaultKey.primed)
        
        return VaultRecord(
            keys: [:], tags: [:],
            ledgerURL: ledgerURL, ledgerMode: ledgerMode,
            untouched: !primed,
            consentGranted: false, consentRevoked: false, consentStampedAt: nil
        )
    }
    
    // MARK: - Veiling
    
    private func veilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict {
            result[k] = veil(v)
        }
        return result
    }
    
    private func unveilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict {
            result[k] = unveil(v) ?? v
        }
        return result
    }
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: ";")
            .replacingOccurrences(of: "/", with: ":")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: ";", with: "+")
            .replacingOccurrences(of: ":", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

// MARK: - Veiled Record (Codable)

struct VeiledRecord: Codable {
    let keys: [String: String]
    let tags: [String: String]
    let ledgerURL: String?
    let ledgerMode: String?
    let untouched: Bool
    let consentGranted: Bool
    let consentRevoked: Bool
    let consentStampedAt: Date?
}

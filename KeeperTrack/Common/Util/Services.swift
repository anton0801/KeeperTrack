import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

final class HTTPLedgerLocator: LedgerLocator {
    
    private let session: URLSession
    private let waitStops: [Double] = [80.0, 160.0, 320.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkFault(reason: "non-HTTP response")
        }
        
        if http.statusCode == 404 {
            throw ServerRejection(httpCode: 404, reason: "endpoint not found")
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw NetworkFault(reason: "HTTP \(http.statusCode)", httpCode: http.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ParsingFault(stage: "JSON parse")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw ParsingFault(stage: "missing 'ok'")
        }
        
        if !ok {
            throw ServerRejection(httpCode: 200, reason: "server ok:false")
        }
        
        guard let url = json["url"] as? String else {
            throw ParsingFault(stage: "missing 'url'")
        }
        
        return url
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""

    
    func locate(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: VaultConstants.backendArchive) else {
            throw ParsingFault(stage: "endpoint URL")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(VaultConstants.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: VaultKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastFault: Error?
        
        for (idx, wait) in waitStops.enumerated() {
            do {
                return try await singleShot(request)
            } catch let rejection as ServerRejection {
                throw rejection
            } catch let netFault as NetworkFault {
                if let retryAfter = netFault.retryAfter {
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                    continue
                }
                lastFault = netFault
                if idx < waitStops.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            } catch {
                lastFault = error
                if idx < waitStops.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            }
        }
        
        if let lastFault = lastFault {
            throw lastFault
        }
        throw NetworkFault(reason: "all retries exhausted")
    }
    
}

final class NotificationConsentSummoner: ConsentSummoner {
    
    func summon() -> AsyncStream<Bool> {
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("\(VaultConstants.logKey) Consent error: \(error)")
            }
            DispatchQueue.main.async {
                continuation.yield(granted)
                continuation.finish()
            }
        }
        
        return stream
    }
    
    func ringPushBell() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class KeeperServiceHolder {
    
    private let _vault: KeeperVault
    private let _sentry: VoltageSentry
    private let _retriever: AttributionRetriever
    private let _locator: LedgerLocator
    private let _summoner: ConsentSummoner
    
    init(
        vault: KeeperVault = CodableKeeperVault(),
        sentry: VoltageSentry = SupabaseVoltageSentry(),
        retriever: AttributionRetriever = AppsFlyerAttributionRetriever(),
        locator: LedgerLocator = HTTPLedgerLocator(),
        summoner: ConsentSummoner = NotificationConsentSummoner()
    ) {
        self._vault = vault
        self._sentry = sentry
        self._retriever = retriever
        self._locator = locator
        self._summoner = summoner
    }
    
    func keeperVault() -> KeeperVault { _vault }
    func voltageSentry() -> VoltageSentry { _sentry }
    func attributionRetriever() -> AttributionRetriever { _retriever }
    func ledgerLocator() -> LedgerLocator { _locator }
    func consentSummoner() -> ConsentSummoner { _summoner }
}

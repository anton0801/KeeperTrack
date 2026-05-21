import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

class AbstractBootstrapper {
    
    final func bootstrap() {
        stepConfigureFirebase()
        stepConfigureMessaging()
        stepConfigureAppsFlyer()
        stepHookLifecycle()
    }
    
    func stepConfigureFirebase() {
        fatalError("Subclass must override stepConfigureFirebase")
    }
    
    func stepConfigureMessaging() {
        fatalError("Subclass must override stepConfigureMessaging")
    }
    
    func stepConfigureAppsFlyer() {
        fatalError("Subclass must override stepConfigureAppsFlyer")
    }
    
    func stepHookLifecycle() {
    }
    
    func kickstart() {
        fatalError("Subclass must override kickstart")
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var bootstrapper: AbstractBootstrapper!
    private let keyWeaver = KeyWeaver()
    private let tagWeaver = TagWeaver()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        keyWeaver.relayKeys = { [weak self] data in
            self?.broadcastKeys(data)
        }
        keyWeaver.relayTags = { [weak self] data in
            self?.broadcastTags(data)
        }
        
        bootstrapper = ConcreteBootstrapper(
            messagingDelegate: self,
            notificationDelegate: self,
            appsFlyerDelegate: self,
            deepLinkDelegate: self
        )
        bootstrapper.bootstrap()
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            tagWeaver.process(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        bootstrapper.kickstart()
    }
    
    private func broadcastKeys(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func broadcastTags(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .init("deeplink_values"),
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: VaultKey.fcm)
            UserDefaults.standard.set(t, forKey: VaultKey.push)
            UserDefaults(suiteName: VaultConstants.suiteVault)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        tagWeaver.process(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        tagWeaver.process(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        tagWeaver.process(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        keyWeaver.acceptKeys(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        keyWeaver.acceptKeys([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        keyWeaver.acceptTags(link.clickEvent)
    }
}

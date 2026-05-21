import AppsFlyerLib
import AppTrackingTransparency
import Combine
import Foundation
import Firebase
import FirebaseCore
import FirebaseMessaging
import SwiftUI

final class ConcreteBootstrapper: AbstractBootstrapper {
    
    private weak var messagingDelegate: MessagingDelegate?
    private weak var notificationDelegate: UNUserNotificationCenterDelegate?
    private weak var appsFlyerDelegate: AppsFlyerLibDelegate?
    private weak var deepLinkDelegate: DeepLinkDelegate?
    
    init(
        messagingDelegate: MessagingDelegate,
        notificationDelegate: UNUserNotificationCenterDelegate,
        appsFlyerDelegate: AppsFlyerLibDelegate,
        deepLinkDelegate: DeepLinkDelegate
    ) {
        self.messagingDelegate = messagingDelegate
        self.notificationDelegate = notificationDelegate
        self.appsFlyerDelegate = appsFlyerDelegate
        self.deepLinkDelegate = deepLinkDelegate
        super.init()
    }
    
    override func stepConfigureFirebase() {
        FirebaseApp.configure()
    }
    
    override func stepConfigureMessaging() {
        Messaging.messaging().delegate = messagingDelegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    override func stepConfigureAppsFlyer() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = VaultConstants.trackerKey
        sdk.appleAppID = VaultConstants.appCode
        sdk.delegate = appsFlyerDelegate
        sdk.deepLinkDelegate = deepLinkDelegate
        sdk.isDebug = false
    }
    
    override func kickstart() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

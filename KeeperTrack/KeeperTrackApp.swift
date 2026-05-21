import SwiftUI

@main
struct KeeperTrackApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var appState = AppState()
    @StateObject private var keeperStore = KeeperStore()
    @StateObject private var penaltyStore = PenaltyStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(keeperStore)
                .environmentObject(penaltyStore)
                .environmentObject(taskStore)
                .environmentObject(notificationManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .preferredColorScheme(appState.colorScheme)
    }
}

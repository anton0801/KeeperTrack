import SwiftUI

@main
struct KeeperTrackApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var keeperStore = KeeperStore()
    @StateObject private var penaltyStore = PenaltyStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(keeperStore)
                .environmentObject(penaltyStore)
                .environmentObject(taskStore)
                .environmentObject(notificationManager)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isVisible: $showSplash)
                    .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
    }
}

import SwiftUI

@main
struct PrepTickApp: App {
    @StateObject private var notificationManager: NotificationManager
    @StateObject private var store: AppStore
    @StateObject private var timerEngine: TimerEngine

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("hasCompletedOnboarding") private var legacyHasCompletedOnboarding: Bool = false

    init() {
        let notificationManager = NotificationManager()
        let store = AppStore(notificationManager: notificationManager)
        _notificationManager = StateObject(wrappedValue: notificationManager)
        _store = StateObject(wrappedValue: store)
        _timerEngine = StateObject(wrappedValue: TimerEngine(store: store))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(onFinish: {
                        hasSeenOnboarding = true
                        legacyHasCompletedOnboarding = true
                    })
                }
            }
            .environmentObject(notificationManager)
            .environmentObject(store)
            .environmentObject(timerEngine)
            .onAppear {
                if legacyHasCompletedOnboarding && !hasSeenOnboarding {
                    hasSeenOnboarding = true
                }
                timerEngine.bind(to: store)
            }
            .tint(Theme.accent)
        }
    }
}

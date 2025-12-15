import SwiftUI

@main
struct PrepTickApp: App {
    @StateObject private var notificationManager: NotificationManager
    @StateObject private var store: AppStore
    @StateObject private var timerEngine = TimerEngine()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    init() {
        let notificationManager = NotificationManager()
        _notificationManager = StateObject(wrappedValue: notificationManager)
        _store = StateObject(wrappedValue: AppStore(notificationManager: notificationManager))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(onFinish: { hasCompletedOnboarding = true })
                }
            }
            .environmentObject(notificationManager)
            .environmentObject(store)
            .environmentObject(timerEngine)
            .tint(Theme.accent)
        }
    }
}

import SwiftUI

@main
struct PrepTickApp: App {
    @StateObject private var notificationManager: NotificationManager
    @StateObject private var store: AppStore
    @StateObject private var timerEngine: TimerEngine

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

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
                if hasCompletedOnboarding {
                    RootTabView()
                } else {
                    OnboardingView(onFinish: { hasCompletedOnboarding = true })
                }
            }
            .environmentObject(notificationManager)
            .environmentObject(store)
            .environmentObject(timerEngine)
            .onAppear {
                timerEngine.bind(to: store)
            }
            .tint(Theme.accent)
        }
    }
}

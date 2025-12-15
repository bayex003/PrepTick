import SwiftUI

@main
struct PrepTickApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var timerEngine = TimerEngine()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(timerEngine)
                .tint(Theme.accent)
        }
    }
}

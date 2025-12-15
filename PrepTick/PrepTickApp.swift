import SwiftUI

@main
struct PrepTickApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Theme.accent)
        }
    }
}

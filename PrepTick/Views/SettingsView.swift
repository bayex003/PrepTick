import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var notificationManager: NotificationManager

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Accent")
                        Spacer()
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 24, height: 24)
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle(isOn: Binding(get: { store.settings.notificationsEnabled }, set: { enabled in
                        store.updateNotificationsEnabled(enabled)

                        if enabled {
                            notificationManager.requestAuthorization()
                        }
                    })) {
                        Label("Timer alerts", systemImage: "bell.fill")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var showingResetAlert = false

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
                    Toggle(isOn: Binding(get: { store.settings.alertsEnabled }, set: { enabled in
                        store.updateAlertsEnabled(enabled)

                        if enabled {
                            notificationManager.requestAuthorization()
                        }
                    })) {
                        Label("Timer alerts", systemImage: "bell.fill")
                    }
                    .accessibilityHint("Enable to allow PrepTick to send timer notifications.")

                    Toggle(isOn: Binding(get: { store.settings.silentModeEnabled }, set: { enabled in
                        store.updateSilentModeEnabled(enabled)
                    })) {
                        Label("Silent mode", systemImage: "bell.slash.fill")
                    }
                    .disabled(!store.settings.alertsEnabled)
                    .accessibilityHint("Mute sounds for alerts while keeping notifications enabled.")
                }

                Section(header: Text("About")) {
                    NavigationLink(destination: AboutView()) {
                        Label("About PrepTick", systemImage: "info.circle")
                    }
                }

                Section(header: Text("Data")) {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset App Data", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .alert("Reset App Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAppData()
                }
            } message: {
                Text("This deletes presets, running timers, settings, and recent sets stored on this device. Onboarding stays marked as completed so you return directly to the app.")
            }
        }
    }
}

#Preview {
    SettingsView()
}

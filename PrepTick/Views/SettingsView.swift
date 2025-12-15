import SwiftUI

struct SettingsView: View {
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
                    Toggle(isOn: .constant(true)) {
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

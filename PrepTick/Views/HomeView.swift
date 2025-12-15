import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next Timer")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("00:00")
                            .font(.system(size: 48, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .materialCardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Stay on track with your latest timers.")
                            .foregroundStyle(.secondary)
                        Button(action: {}) {
                            Label("Start a quick timer", systemImage: "play.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .materialCardStyle(cornerRadius: Theme.cornerRadiusMedium)
                }
                .padding()
            }
            .navigationTitle("PrepTick")
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    HomeView()
}

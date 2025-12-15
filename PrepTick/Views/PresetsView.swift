import SwiftUI

struct PresetsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<3) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preset \(index + 1)")
                                .font(.headline)
                            Text("A calm starting point for your timers.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .materialCardStyle()
                    }

                    Button(action: {}) {
                        Label("Create preset", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
                .padding()
            }
            .navigationTitle("Presets")
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    PresetsView()
}

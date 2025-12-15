import SwiftUI

struct RepeatLastSetCardView: View {
    let presets: [Preset]
    let lastPlayedAt: Date?
    var onRepeat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Repeat Last Set")
                        .font(.title3.weight(.semibold))
                    if let lastPlayedAt {
                        Text("Saved \(lastPlayedAt, style: .time)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            presetsSummary

            Button(action: onRepeat) {
                HStack {
                    Spacer()
                    Text("Repeat Set")
                        .font(.headline)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Theme.accent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .materialCardStyle()
    }

    private var presetsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Includes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            FlexibleChips(items: presets.map { $0.displayLabel })
        }
    }
}

private struct FlexibleChips: View {
    let items: [String]
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.14))
                    .foregroundStyle(Theme.accent)
                    .clipShape(Capsule())
            }
        }
    }
}

private extension Preset {
    var displayLabel: String {
        "\(name) • \(formattedDuration)"
    }
}

#Preview {
    RepeatLastSetCardView(
        presets: [
            Preset(name: "Soft Boiled Eggs", durationSeconds: 360, category: .breakfast),
            Preset(name: "Toast", durationSeconds: 180, category: .breakfast),
            Preset(name: "Coffee", durationSeconds: 240, category: .beverage)
        ],
        lastPlayedAt: .now
    ) {
        
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

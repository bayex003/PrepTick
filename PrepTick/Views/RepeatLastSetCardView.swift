import SwiftUI

struct RepeatLastSetCardView: View {
    let items: [LastSet]
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
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .truncationMode(.tail)
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
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Theme.accent)
            .controlSize(.large)
            .shadow(color: Theme.accent.opacity(0.12), radius: 10, y: 6)
            .accessibilityLabel("Repeat set")
            .accessibilityHint("Restarts the previous set of timers.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .materialCardStyle()
    }

    private var presetsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Includes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            FlexibleChips(items: items.map { $0.displayLabel })
        }
    }

    private var lastPlayedAt: Date? {
        items.map(\.setAt).max()
    }

    private var subtitle: String {
        items.prefix(3).map { $0.name }.joined(separator: ", ")
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

private extension LastSet {
    var displayLabel: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = durationSeconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        let duration = formatter.string(from: TimeInterval(durationSeconds)) ?? "\(durationSeconds / 60)m"
        return "\(name) • \(duration)"
    }
}

#Preview {
    RepeatLastSetCardView(
        items: [
            LastSet(preset: Preset(name: "Soft Boiled Eggs", durationSeconds: 360, category: .breakfast)),
            LastSet(preset: Preset(name: "Toast", durationSeconds: 180, category: .breakfast)),
            LastSet(preset: Preset(name: "Coffee", durationSeconds: 240, category: .beverage))
        ]
    ) {

    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

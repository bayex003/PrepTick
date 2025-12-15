import SwiftUI

struct TimerTileView: View {
    let timer: RunningTimer
    let now: Date

    private var remaining: Int {
        max(0, Int(timer.endAt.timeIntervalSince(now)))
    }

    private var progress: Double {
        let total = Double(timer.preset.durationSeconds)
        guard total > 0 else { return 0 }
        return 1 - min(1, Double(remaining) / total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: timer.preset.category.icon)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(timer.preset.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(timer.preset.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 12) {
                Text(formattedTime(remaining))
                    .font(.system(size: 38, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                    Text("Started \(timer.startedAt, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .materialCardStyle(cornerRadius: Theme.cornerRadiusMedium)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        return formatter.string(from: TimeInterval(seconds)) ?? "--:--"
    }
}

#Preview {
    TimerTileView(
        timer: RunningTimer(
            preset: Preset(name: "Soft Boiled Eggs", durationSeconds: 360, category: .breakfast),
            endAt: .now.addingTimeInterval(320)
        ),
        now: .now
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

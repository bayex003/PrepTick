import SwiftUI

struct TimerTileView: View {
    @EnvironmentObject private var store: AppStore
    let timer: RunningTimer
    let now: Date
    var onSelect: (() -> Void)? = nil

    private var remaining: Int {
        timer.remainingSeconds(at: now)
    }

    private var isDone: Bool {
        remaining == 0
    }

    private var isPaused: Bool {
        timer.isPaused
    }

    private var progress: Double {
        let total = Double(timer.preset.durationSeconds)
        guard total > 0 else { return 0 }
        return 1 - min(1, Double(remaining) / total)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .materialCardStyle(cornerRadius: Theme.cornerRadiusMedium)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: timer.preset.category.icon)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(timer.preset.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text(timer.preset.category.displayName)
                            .font(.subheadline)
                        if isPaused {
                            Label("Paused", systemImage: "pause.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if isDone {
                doneState
            } else {
                runningState
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
    }

    private var runningState: some View {
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

    private var doneState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Done")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Finished at \(timer.endAt, style: .time)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Restart") {
                    store.restartTimer(timer)
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    store.clearTimer(timer)
                }
                .buttonStyle(.bordered)
            }
            .font(.subheadline)
        }
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
    .environmentObject(AppStore())
    .environmentObject(TimerEngine())
}

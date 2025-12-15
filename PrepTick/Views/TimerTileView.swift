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
        timer.state == .done || remaining == 0
    }

    private var isPaused: Bool {
        timer.isPaused
    }

    private var isRunning: Bool {
        timer.state == .running && !isPaused && !isDone
    }

    private var progress: Double {
        let total = Double(timer.preset.durationSeconds)
        guard total > 0 else { return 0 }
        return 1 - min(1, Double(remaining) / total)
    }

    private var stateDescription: String {
        if isDone { return "done" }
        if isPaused { return "paused" }
        return "running"
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(tileBackground)
            .overlay(tileBorder)
            .shadow(color: Theme.accent.opacity(isRunning ? 0.16 : 0.08), radius: isRunning ? 12 : 10, x: 0, y: isRunning ? 6 : 4)
            .animation(.easeInOut(duration: 0.2), value: isDone)
            .animation(.easeInOut(duration: 0.2), value: isPaused)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabelText)
            .accessibilityHint("Double tap to view timer controls.")
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
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
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
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Theme.accent)
                Text("Started \(timer.startedAt, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var doneState: some View {
        VStack(alignment: .leading, spacing: 10) {
            doneBadge
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent.opacity(0.85))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Finished")
                        .font(.title3.weight(.semibold))
                    Text("Wrapped at \(finishTime, style: .time)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Button("Restart") {
                    store.restartTimer(timer)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.large)
                .font(.headline)
                .buttonBorderShape(.capsule)
                .accessibilityLabel("Restart timer")
                .accessibilityHint("Restarts \(timer.preset.name) from the beginning.")

                Button("Clear") {
                    store.clearTimer(timer)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .font(.subheadline.weight(.semibold))
                .accessibilityLabel("Clear timer")
                .accessibilityHint("Removes \(timer.preset.name) from running timers.")
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        return formatter.string(from: TimeInterval(seconds)) ?? "--:--"
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium, style: .continuous)
                    .fill(tileTint.opacity(tileOverlayOpacity))
            )
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium, style: .continuous)
            .stroke(tileTint.opacity(tileBorderOpacity), lineWidth: borderWidth)
    }

    private var tileTint: Color { Theme.accent }

    private var finishTime: Date { timer.endAt ?? timer.startedAt }

    private var tileOverlayOpacity: Double {
        if isDone {
            return 0.14
        } else if isPaused {
            return 0.12
        } else {
            return 0.24
        }
    }

    private var tileBorderOpacity: Double {
        if isDone {
            return 0.28
        } else if isPaused {
            return 0.26
        } else {
            return 0.42
        }
    }

    private var borderWidth: CGFloat {
        if isRunning {
            return 1.8
        } else if isDone {
            return 1.6
        } else {
            return 1.2
        }
    }

    private var doneBadge: some View {
        Label("Done", systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.accent.opacity(0.16))
            .foregroundStyle(Theme.accent)
            .clipShape(Capsule())
    }

    private var accessibilityLabelText: Text {
        Text("\(timer.preset.name), \(formattedTime(remaining)) remaining, \(stateDescription)")
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

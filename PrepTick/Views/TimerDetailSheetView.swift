import SwiftUI

struct TimerDetailSheetView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var timerEngine: TimerEngine
    @Environment(\.dismiss) private var dismiss

    let timerID: UUID

    @State private var name: String = ""

    private var timer: RunningTimer? {
        store.runningTimers.first(where: { $0.id == timerID })
    }

    private var remaining: Int {
        guard let timer else { return 0 }
        return timer.remainingSeconds(at: timerEngine.now)
    }

    private var isDone: Bool {
        guard let timer else { return false }
        return timer.state == .done || remaining == 0
    }

    private var progress: Double {
        guard let timer else { return 0 }
        let total = Double(max(timer.preset.durationSeconds, 1))
        return 1 - min(1, Double(remaining) / total)
    }

    private var isPaused: Bool {
        timer?.isPaused ?? false
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if let timer {
                    header(for: timer)
                    progressSection
                    controls(for: timer)
                    Spacer()
                } else {
                    ContentUnavailableView("Timer Removed", systemImage: "stopwatch", description: Text("This timer is no longer active."))
                }
            }
            .padding()
            .navigationTitle("Timer Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                name = timer?.preset.name ?? ""
            }
            .onChange(of: timer?.preset.name ?? "") { newValue in
                if newValue != name {
                    name = newValue
                }
            }
        }
    }

    private func header(for timer: RunningTimer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Timer name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { rename(timer) }
                .submitLabel(.done)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formattedTime(remaining))
                        .font(.system(size: 42, weight: .bold, design: .monospaced))

                    Label(stateLabel, systemImage: stateIcon)
                        .foregroundStyle(stateColor)
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label(timer.preset.category.displayName, systemImage: timer.preset.category.icon)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            HStack {
                Text("Elapsed")
                    .foregroundStyle(.secondary)
                Spacer()
                if let timer = timer {
                    Text("Started \(timer.startedAt, style: .time)")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
    }

    private func controls(for timer: RunningTimer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button(isPaused ? "Resume" : "Pause") {
                    togglePause(timer)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDone)

                Button("Stop") {
                    store.clearTimer(timer)
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Button {
                    store.adjustTimer(timer, by: -60, now: timerEngine.now)
                } label: {
                    Label("-1 min", systemImage: "minus.circle")
                }
                .buttonStyle(.bordered)
                .disabled(isDone)

                Button {
                    store.adjustTimer(timer, by: 60, now: timerEngine.now)
                } label: {
                    Label("+1 min", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
                .disabled(isDone)
            }

            Button {
                rename(timer)
            } label: {
                Label("Rename", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func togglePause(_ timer: RunningTimer) {
        guard !isDone else { return }
        if timer.isPaused {
            store.resumeTimer(timer, now: timerEngine.now)
        } else {
            store.pauseTimer(timer, now: timerEngine.now)
        }
    }

    private func rename(_ timer: RunningTimer) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            name = timer.preset.name
            return
        }

        store.renameTimer(timer, to: trimmed)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        return formatter.string(from: TimeInterval(seconds)) ?? "--:--"
    }

    private var stateLabel: String {
        guard let timer else { return "Running" }
        if isDone { return "Done" }
        return timer.isPaused ? "Paused" : "Running"
    }

    private var stateIcon: String {
        guard let timer else { return "play.fill" }
        if isDone { return "checkmark.circle.fill" }
        return timer.isPaused ? "pause.fill" : "play.fill"
    }

    private var stateColor: Color {
        guard let timer else { return .green }
        if isDone { return .secondary }
        return timer.isPaused ? .orange : .green
    }
}

#Preview {
    TimerDetailSheetView(timerID: UUID())
        .environmentObject(AppStore())
        .environmentObject(TimerEngine())
}

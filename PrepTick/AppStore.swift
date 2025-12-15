import Foundation
import SwiftUI

@MainActor
class AppStore: ObservableObject {
    @Published var presets: [Preset] = []
    @Published var runningTimers: [RunningTimer] = []
    @Published var settings: Settings = Settings()
    @Published var lastSet: [LastSet] = []

    @AppStorage("didSeedDefaults") private var didSeedDefaults: Bool = false

    private let presetsKey = "presets"
    private let runningTimersKey = "runningTimers"
    private let settingsKey = "settings"
    private let lastSetKey = "lastSet"
    private let setGroupingWindow: TimeInterval = 90

    private let notificationManager: NotificationManager

    init(notificationManager: NotificationManager = NotificationManager()) {
        self.notificationManager = notificationManager

        load()
        reconcileRunningTimers()
        notificationManager.reconcilePendingNotifications(matching: runningTimers)
        refreshNotifications()
    }

    func resetAppData(keepingOnboardingSeen: Bool = true) {
        notificationManager.cancelNotifications(for: runningTimers.map { $0.id })

        let defaults = UserDefaults.standard
        [presetsKey, runningTimersKey, settingsKey, lastSetKey].forEach { key in
            UserDefaultsStore.removeValue(forKey: key, defaults: defaults)
        }

        if keepingOnboardingSeen {
            defaults.set(true, forKey: "hasSeenOnboarding")
            defaults.set(true, forKey: "hasCompletedOnboarding")
        }

        didSeedDefaults = false
        load()
        notificationManager.reconcilePendingNotifications(matching: runningTimers)
    }

    func load() {
        if !didSeedDefaults {
            presets = DefaultsSeeder.seedPresets()
            UserDefaultsStore.save(presets, forKey: presetsKey)
            didSeedDefaults = true
        } else {
            presets = UserDefaultsStore.load([Preset].self, forKey: presetsKey) ?? []
        }

        runningTimers = UserDefaultsStore.load([RunningTimer].self, forKey: runningTimersKey) ?? []
        settings = UserDefaultsStore.load(Settings.self, forKey: settingsKey) ?? Settings()
        lastSet = UserDefaultsStore.load([LastSet].self, forKey: lastSetKey) ?? []
    }

    func save() {
        UserDefaultsStore.save(presets, forKey: presetsKey)
        UserDefaultsStore.save(runningTimers, forKey: runningTimersKey)
        UserDefaultsStore.save(settings, forKey: settingsKey)
        UserDefaultsStore.save(lastSet, forKey: lastSetKey)
    }

    func startPreset(_ preset: Preset) {
        guard preset.durationSeconds > 0 else { return }

        let now = Date()
        let endAt = now.addingTimeInterval(TimeInterval(preset.durationSeconds))
        let runningTimer = RunningTimer(preset: preset, startedAt: now, endAt: endAt, state: .running)

        runningTimers.append(runningTimer)
        updateLastSet(with: preset, startedAt: now)
        save()
        scheduleNotificationIfNeeded(for: runningTimer, now: now)
    }

    func repeatLastSet(now: Date = .now) {
        let presetMap = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
        let setsToStart = lastSet

        guard !setsToStart.isEmpty else { return }

        notificationManager.cancelNotifications(for: runningTimers.map { $0.id })
        runningTimers.removeAll()

        var refreshedSet: [LastSet] = []

        for item in setsToStart {
            let preset = presetMap[item.presetID] ?? item.snapshotPreset
            guard preset.durationSeconds > 0 else { continue }
            let refreshedItem = LastSet(id: item.id, preset: preset, setAt: now)
            refreshedSet.append(refreshedItem)

            let endAt = now.addingTimeInterval(TimeInterval(preset.durationSeconds))
            let runningTimer = RunningTimer(preset: preset, startedAt: now, endAt: endAt, state: .running)
            runningTimers.append(runningTimer)
            scheduleNotificationIfNeeded(for: runningTimer, now: now)
        }

        lastSet = refreshedSet
        save()
    }

    func toggleFavorite(for preset: Preset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index].isFavorite.toggle()
        save()
    }

    func addPreset(_ preset: Preset) {
        presets.append(preset)
        save()
    }

    func updatePreset(_ preset: Preset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index] = preset
        save()
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        save()
    }

    func clearTimer(_ timer: RunningTimer) {
        notificationManager.cancelNotification(for: timer.id)
        runningTimers.removeAll { $0.id == timer.id }
        save()
    }

    func restartTimer(_ timer: RunningTimer) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        let now = Date()
        guard runningTimers[index].preset.durationSeconds > 0 else {
            runningTimers[index].state = .done
            runningTimers[index].pausedRemainingSeconds = nil
            runningTimers[index].endAt = runningTimers[index].endAt ?? now
            notificationManager.cancelNotification(for: timer.id)
            save()
            return
        }
        runningTimers[index].startedAt = now
        runningTimers[index].endAt = now.addingTimeInterval(TimeInterval(timer.preset.durationSeconds))
        runningTimers[index].pausedRemainingSeconds = nil
        runningTimers[index].state = .running
        save()
        scheduleNotificationIfNeeded(for: runningTimers[index], now: now)
    }

    func pauseTimer(_ timer: RunningTimer, now: Date = .now) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        let remaining = runningTimers[index].remainingSeconds(at: now)
        runningTimers[index].pausedRemainingSeconds = remaining
        runningTimers[index].endAt = nil
        runningTimers[index].state = .paused
        save()
        notificationManager.cancelNotification(for: timer.id)
    }

    func resumeTimer(_ timer: RunningTimer, now: Date = .now) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        guard let pausedRemainingSeconds = runningTimers[index].pausedRemainingSeconds else { return }

        if pausedRemainingSeconds <= 0 {
            runningTimers[index].pausedRemainingSeconds = nil
            runningTimers[index].endAt = now
            runningTimers[index].state = .done
            save()
            return
        }

        let totalDuration = runningTimers[index].preset.durationSeconds
        let endAt = now.addingTimeInterval(TimeInterval(pausedRemainingSeconds))
        runningTimers[index].endAt = endAt
        runningTimers[index].startedAt = endAt.addingTimeInterval(TimeInterval(-totalDuration))
        runningTimers[index].pausedRemainingSeconds = nil
        runningTimers[index].state = .running
        save()
        scheduleNotificationIfNeeded(for: runningTimers[index], now: now)
    }

    func adjustTimer(_ timer: RunningTimer, by adjustmentSeconds: Int, now: Date = .now) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }

        let currentTimer = runningTimers[index]
        let remaining = currentTimer.remainingSeconds(at: now)
        let elapsed = max(0, currentTimer.preset.durationSeconds - remaining)

        let newRemaining = max(0, remaining + adjustmentSeconds)
        let newTotal = max(0, newRemaining + elapsed)

        runningTimers[index].preset.durationSeconds = newTotal

        switch currentTimer.state {
        case .paused:
            runningTimers[index].pausedRemainingSeconds = newRemaining
            runningTimers[index].endAt = nil
        case .running:
            let endAt = now.addingTimeInterval(TimeInterval(newRemaining))
            runningTimers[index].endAt = endAt
            runningTimers[index].startedAt = endAt.addingTimeInterval(TimeInterval(-newTotal))
        case .done:
            runningTimers[index].endAt = runningTimers[index].endAt ?? now
        }

        if newRemaining == 0 {
            runningTimers[index].state = .done
            runningTimers[index].pausedRemainingSeconds = nil
            runningTimers[index].endAt = runningTimers[index].endAt ?? now
        } else if runningTimers[index].state == .done {
            runningTimers[index].state = .running
            runningTimers[index].pausedRemainingSeconds = nil
        }

        save()
        updateNotification(for: runningTimers[index], now: now)
    }

    func markTimerDone(at index: Int, date: Date) {
        guard runningTimers.indices.contains(index) else { return }
        runningTimers[index].state = .done
        runningTimers[index].pausedRemainingSeconds = nil
        runningTimers[index].endAt = runningTimers[index].endAt ?? date
        notificationManager.cancelNotification(for: runningTimers[index].id)
    }

    func renameTimer(_ timer: RunningTimer, to newName: String) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        runningTimers[index].preset.name = newName
        save()
        updateNotification(for: runningTimers[index])
    }

    func updateAlertsEnabled(_ enabled: Bool) {
        settings.alertsEnabled = enabled
        save()

        if enabled {
            refreshNotifications()
        } else {
            notificationManager.cancelNotifications(for: runningTimers.map { $0.id })
        }
    }

    func updateSilentModeEnabled(_ enabled: Bool) {
        settings.silentModeEnabled = enabled
        save()
        refreshNotifications()
    }

    private func scheduleNotificationIfNeeded(for timer: RunningTimer, now: Date = .now) {
        guard settings.alertsEnabled, timer.state == .running, timer.endAt != nil else { return }
        notificationManager.scheduleNotification(for: timer, alertsEnabled: settings.alertsEnabled, silentModeEnabled: settings.silentModeEnabled, now: now)
    }

    private func updateNotification(for timer: RunningTimer, now: Date = .now) {
        notificationManager.cancelNotification(for: timer.id)
        scheduleNotificationIfNeeded(for: timer, now: now)
    }

    private func refreshNotifications() {
        for timer in runningTimers {
            updateNotification(for: timer)
        }
    }

    private func updateLastSet(with preset: Preset, startedAt: Date) {
        let lastDate = lastSet.map(\.setAt).max() ?? .distantPast
        if startedAt.timeIntervalSince(lastDate) > setGroupingWindow {
            lastSet = []
        }

        lastSet.append(LastSet(preset: preset, setAt: startedAt))
    }

    @discardableResult
    func reconcileRunningTimers(now: Date = .now) -> Bool {
        var didUpdate = false

        for index in runningTimers.indices {
            let remaining = runningTimers[index].remainingSeconds(at: now)

            if runningTimers[index].preset.durationSeconds <= 0 {
                runningTimers[index].state = .done
                runningTimers[index].pausedRemainingSeconds = nil
                runningTimers[index].endAt = runningTimers[index].endAt ?? now
                notificationManager.cancelNotification(for: runningTimers[index].id)
                didUpdate = true
                continue
            }

            switch runningTimers[index].state {
            case .running:
                if remaining <= 0 {
                    runningTimers[index].state = .done
                    runningTimers[index].pausedRemainingSeconds = nil
                    runningTimers[index].endAt = runningTimers[index].endAt ?? now
                    notificationManager.cancelNotification(for: runningTimers[index].id)
                    didUpdate = true
                }
            case .paused:
                let clamped = max(0, runningTimers[index].pausedRemainingSeconds ?? remaining)
                if runningTimers[index].pausedRemainingSeconds != clamped {
                    runningTimers[index].pausedRemainingSeconds = clamped
                    didUpdate = true
                }
            case .done:
                if runningTimers[index].pausedRemainingSeconds != nil {
                    runningTimers[index].pausedRemainingSeconds = nil
                    didUpdate = true
                }
            }
        }

        if didUpdate {
            save()
        }

        return didUpdate
    }
}

#if DEBUG
extension AppStore {
    func loadDemoTimers(now: Date = .now) {
        notificationManager.cancelNotifications(for: runningTimers.map { $0.id })

        let demos: [(String, Int, Category)] = [
            ("Chicken", 14 * 60 + 45, .dinner),
            ("Rice", 15 * 60 + 20, .prep),
            ("Broccoli", 3 * 60 + 25, .prep)
        ]

        runningTimers = demos.map { name, duration, category in
            let preset = Preset(name: name, durationSeconds: duration, category: category)
            return RunningTimer(
                preset: preset,
                startedAt: now,
                endAt: now.addingTimeInterval(TimeInterval(duration)),
                state: .running
            )
        }

        lastSet = runningTimers.map { LastSet(preset: $0.preset, setAt: now) }
        save()

        for timer in runningTimers {
            notificationManager.scheduleNotification(
                for: timer,
                alertsEnabled: settings.alertsEnabled,
                silentModeEnabled: settings.silentModeEnabled,
                now: now
            )
        }

        notificationManager.reconcilePendingNotifications(matching: runningTimers)
    }
}
#endif

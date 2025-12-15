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

    private let notificationManager: NotificationManager

    init(notificationManager: NotificationManager = NotificationManager()) {
        self.notificationManager = notificationManager

        load()
        refreshNotifications()
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
        let now = Date()
        let endAt = now.addingTimeInterval(TimeInterval(preset.durationSeconds))
        let runningTimer = RunningTimer(preset: preset, startedAt: now, endAt: endAt)

        runningTimers.append(runningTimer)
        lastSet.append(LastSet(presetID: preset.id, setAt: now))
        save()
        scheduleNotificationIfNeeded(for: runningTimer, now: now)
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
        runningTimers[index].startedAt = now
        runningTimers[index].endAt = now.addingTimeInterval(TimeInterval(timer.preset.durationSeconds))
        runningTimers[index].pausedRemainingSeconds = nil
        save()
        scheduleNotificationIfNeeded(for: runningTimers[index], now: now)
    }

    func pauseTimer(_ timer: RunningTimer, now: Date = .now) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        let remaining = runningTimers[index].remainingSeconds(at: now)
        runningTimers[index].pausedRemainingSeconds = remaining
        runningTimers[index].endAt = now
        save()
        notificationManager.cancelNotification(for: timer.id)
    }

    func resumeTimer(_ timer: RunningTimer, now: Date = .now) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        guard let pausedRemainingSeconds = runningTimers[index].pausedRemainingSeconds else { return }

        let totalDuration = runningTimers[index].preset.durationSeconds
        let endAt = now.addingTimeInterval(TimeInterval(pausedRemainingSeconds))
        runningTimers[index].endAt = endAt
        runningTimers[index].startedAt = endAt.addingTimeInterval(TimeInterval(-totalDuration))
        runningTimers[index].pausedRemainingSeconds = nil
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

        if currentTimer.isPaused {
            runningTimers[index].pausedRemainingSeconds = newRemaining
            runningTimers[index].endAt = now
            runningTimers[index].startedAt = now.addingTimeInterval(TimeInterval(-newTotal))
        } else {
            let endAt = now.addingTimeInterval(TimeInterval(newRemaining))
            runningTimers[index].endAt = endAt
            runningTimers[index].startedAt = endAt.addingTimeInterval(TimeInterval(-newTotal))
        }

        save()
        updateNotification(for: runningTimers[index], now: now)
    }

    func renameTimer(_ timer: RunningTimer, to newName: String) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        runningTimers[index].preset.name = newName
        save()
        updateNotification(for: runningTimers[index])
    }

    func updateNotificationsEnabled(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        save()

        if enabled {
            refreshNotifications()
        } else {
            notificationManager.cancelNotifications(for: runningTimers.map { $0.id })
        }
    }

    private func scheduleNotificationIfNeeded(for timer: RunningTimer, now: Date = .now) {
        guard settings.notificationsEnabled, !timer.isPaused else { return }
        notificationManager.scheduleNotification(for: timer, now: now)
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
}

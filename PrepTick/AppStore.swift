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

    init() {
        load()
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
        runningTimers.removeAll { $0.id == timer.id }
        save()
    }

    func restartTimer(_ timer: RunningTimer) {
        guard let index = runningTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        let now = Date()
        runningTimers[index].startedAt = now
        runningTimers[index].endAt = now.addingTimeInterval(TimeInterval(timer.preset.durationSeconds))
        save()
    }
}

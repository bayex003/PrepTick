import Combine
import Foundation

@MainActor
final class TimerEngine: ObservableObject {
    @Published var now: Date = .now

    private var cancellable: AnyCancellable?
    private weak var store: AppStore?

    init(store: AppStore? = nil, interval: TimeInterval = 0.5) {
        self.store = store
        cancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.handleTick(date)
            }
    }

    func bind(to store: AppStore) {
        self.store = store
        store.reconcileRunningTimers(now: now)
    }

    private func handleTick(_ date: Date) {
        now = date
        guard let store else { return }

        var didUpdate = false

        for index in store.runningTimers.indices {
            let remaining = store.runningTimers[index].remainingSeconds(at: date)

            switch store.runningTimers[index].state {
            case .running:
                if remaining <= 0 {
                    store.markTimerDone(at: index, date: date)
                    didUpdate = true
                }
            case .paused:
                store.runningTimers[index].pausedRemainingSeconds = max(0, store.runningTimers[index].pausedRemainingSeconds ?? 0)
            case .done:
                continue
            }
        }

        if didUpdate {
            store.save()
        }
    }
}

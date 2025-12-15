import Combine
import Foundation

@MainActor
final class TimerEngine: ObservableObject {
    @Published var now: Date = .now

    private var cancellable: AnyCancellable?

    init(interval: TimeInterval = 0.5) {
        cancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }
}

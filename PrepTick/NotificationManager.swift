import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    init() {
        Task {
            await refreshAuthorizationStatus()
        }
    }

    func requestAuthorization() {
        Task {
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                print("Notification authorization failed: \(error)")
            }

            await refreshAuthorizationStatus()
        }
    }

    func scheduleNotification(for timer: RunningTimer, alertsEnabled: Bool, silentModeEnabled: Bool, now: Date = .now) {
        Task {
            await refreshAuthorizationStatus()

            guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }
            guard alertsEnabled else {
                cancelNotification(for: timer.id)
                return
            }

            let remaining = timer.remainingSeconds(at: now)
            guard remaining > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = "PrepTick"
            content.body = "\(timer.preset.name) done."

            if !silentModeEnabled {
                content.sound = .default
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remaining), repeats: false)
            let request = UNNotificationRequest(identifier: notificationIdentifier(for: timer.id), content: content, trigger: trigger)

            cancelNotification(for: timer.id)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelNotification(for timerID: UUID) {
        let identifiers = [notificationIdentifier(for: timerID)]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancelNotifications(for timerIDs: [UUID]) {
        let identifiers = timerIDs.map { notificationIdentifier(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func notificationIdentifier(for timerID: UUID) -> String {
        "timer_\(timerID.uuidString)"
    }

    // Debug helper for manual notification testing:
    // func scheduleTestNotification() {
    //     // Run on device/simulator: call this, then lock the screen.
    //     // A notification should appear in ~5 seconds if alerts are permitted.
    //     let content = UNMutableNotificationContent()
    //     content.title = "PrepTick"
    //     content.body = "Test notification"
    //     let request = UNNotificationRequest(identifier: "debug_preptick", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
    //     Task { try? await center.add(request) }
    // }

    private func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
}

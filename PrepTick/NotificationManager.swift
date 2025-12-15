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

    func scheduleNotification(for timer: RunningTimer, now: Date = .now) {
        Task {
            await refreshAuthorizationStatus()

            guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }

            let remaining = timer.remainingSeconds(at: now)
            guard remaining > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = timer.preset.name
            content.body = "Timer finished"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remaining), repeats: false)
            let request = UNNotificationRequest(identifier: timer.id.uuidString, content: content, trigger: trigger)

            cancelNotification(for: timer.id)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelNotification(for timerID: UUID) {
        let identifiers = [timerID.uuidString]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancelNotifications(for timerIDs: [UUID]) {
        let identifiers = timerIDs.map { $0.uuidString }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
}

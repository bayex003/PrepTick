import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

struct OnboardingView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var store: AppStore

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var currentIndex: Int = 0

    let onFinish: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(title: "Dial in meals", subtitle: "Save presets for your go-to dishes and start them in a tap.", icon: "dial.min.fill"),
        OnboardingPage(title: "See it all", subtitle: "Track multiple timers at once without losing your place.", icon: "rectangle.grid.2x2.fill"),
        OnboardingPage(title: "Stay on pace", subtitle: "Pause, resume, or adjust timers as plans change.", icon: "clock.arrow.circlepath"),
        OnboardingPage(title: "Enable alerts", subtitle: "Get a heads up when food is ready. You can change this anytime in Settings.", icon: "bell.badge.fill")
    ]

    var body: some View {
        VStack(spacing: 32) {
            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.1.id) { index, page in
                    onboardingCard(for: page)
                        .tag(index)
                        .padding(.horizontal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            if isOnLastPage {
                notificationActions
            } else {
                nextButton
            }

            Button("Skip") {
                completeOnboarding(requestPermission: false)
            }
            .padding(.bottom)
        }
    }

    private var isOnLastPage: Bool { currentIndex == pages.count - 1 }

    private func onboardingCard(for page: OnboardingPage) -> some View {
        VStack(spacing: 18) {
            Image(systemName: page.icon)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Theme.accent)

            Text(page.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var nextButton: some View {
        Button {
            withAnimation {
                currentIndex = min(currentIndex + 1, pages.count - 1)
            }
        } label: {
            Text("Next")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
    }

    private var notificationActions: some View {
        VStack(spacing: 12) {
            Button {
                completeOnboarding(requestPermission: true)
            } label: {
                Label("Allow Notifications", systemImage: "bell.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                completeOnboarding(requestPermission: false)
            } label: {
                Text("Maybe later")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }

    private func completeOnboarding(requestPermission: Bool) {
        store.updateNotificationsEnabled(requestPermission)

        if requestPermission {
            notificationManager.requestAuthorization()
        }

        hasCompletedOnboarding = true
        onFinish()
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .environmentObject(NotificationManager())
        .environmentObject(AppStore())
}

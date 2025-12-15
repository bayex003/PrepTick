import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var timerEngine: TimerEngine

    @State private var selectedTimer: RunningTimer?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible())
    ]

    private var favoritePresets: [Preset] {
        store.presets.filter { $0.isFavorite }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !favoritePresets.isEmpty {
                        favoritesSection
                    }

                    if store.runningTimers.isEmpty {
                        emptyState
                    } else {
                        timersGrid
                    }
                }
                .padding()
            }
            .navigationTitle("PrepTick")
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedTimer) { timer in
                TimerDetailSheetView(timerID: timer.id)
                    .presentationDetents([.medium, .large])
            }
            .onChange(of: store.runningTimers) { timers in
                guard let selectedTimer else { return }
                if !timers.contains(where: { $0.id == selectedTimer.id }) {
                    self.selectedTimer = nil
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Favorites")
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(favoritePresets) { preset in
                        Button {
                            store.startPreset(preset)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: preset.category.icon)
                                Text(preset.name)
                                Text(preset.formattedDuration)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Theme.accent.opacity(0.15))
                            .foregroundStyle(Theme.accent)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var timersGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Running Timers")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                ForEach(store.runningTimers) { timer in
                    TimerTileView(timer: timer, now: timerEngine.now) {
                        selectedTimer = timer
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No timers running")
                .font(.headline)
            Text("Start a favorite to get cooking.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStore())
        .environmentObject(TimerEngine())
}

import SwiftUI

struct PresetRowView: View {
    let preset: Preset
    let onFavoriteToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: preset.category.icon)
                        .foregroundStyle(.secondary)
                    Text(preset.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(preset.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(preset.formattedDuration)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onFavoriteToggle) {
                Image(systemName: preset.isFavorite ? "star.fill" : "star")
                    .imageScale(.large)
                    .foregroundStyle(preset.isFavorite ? .yellow : .secondary)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(preset.isFavorite ? Theme.accent.opacity(0.15) : Color(.systemGray5))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(preset.isFavorite ? "Remove favorite" : "Mark favorite")
            .accessibilityHint("Toggles favorite for \(preset.name).")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .materialCardStyle(cornerRadius: Theme.cornerRadiusMedium)
    }
}

#Preview {
    PresetRowView(
        preset: Preset(name: "Soft Boiled Eggs", durationSeconds: 360, category: .breakfast, isFavorite: true),
        onFavoriteToggle: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

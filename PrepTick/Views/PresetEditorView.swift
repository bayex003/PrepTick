import SwiftUI

struct PresetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    private let preset: Preset?
    let onSave: (Preset) -> Void

    @State private var name: String
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var useMinutesOnly: Bool
    @State private var category: Category
    @State private var isFavorite: Bool

    init(preset: Preset?, onSave: @escaping (Preset) -> Void) {
        self.preset = preset
        self.onSave = onSave
        _name = State(initialValue: preset?.name ?? "")
        let duration = preset?.durationSeconds ?? 300
        _minutes = State(initialValue: duration / 60)
        _seconds = State(initialValue: duration % 60)
        _useMinutesOnly = State(initialValue: preset?.durationSeconds.isMultiple(of: 60) ?? true)
        _category = State(initialValue: preset?.category ?? .prep)
        _isFavorite = State(initialValue: preset?.isFavorite ?? false)
    }

    private var durationSeconds: Int {
        let total = (minutes * 60) + (useMinutesOnly ? 0 : seconds)
        return max(total, 0)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && durationSeconds > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                }

                Section("Duration") {
                    Toggle("Minutes only", isOn: $useMinutesOnly.animation())
                    Stepper(value: $minutes, in: 0...240) {
                        HStack {
                            Text("Minutes")
                            Spacer()
                            Text("\(minutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !useMinutesOnly {
                        Stepper(value: $seconds, in: 0...59) {
                            HStack {
                                Text("Seconds")
                                Spacer()
                                Text("\(seconds) sec")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text("Total")
                        Spacer()
                        Text(timeString(from: durationSeconds))
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section("Options") {
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle(preset == nil ? "New Preset" : "Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityLabel("Save preset")
                        .accessibilityHint("Saves your changes to this preset.")
                }
            }
        }
    }

    private func timeString(from seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds) sec"
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedPreset = Preset(
            id: preset?.id ?? UUID(),
            name: trimmedName,
            durationSeconds: durationSeconds,
            category: category,
            isFavorite: isFavorite
        )
        onSave(updatedPreset)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PresetEditorView(preset: Preset(name: "Soft Boiled Eggs", durationSeconds: 360, category: .breakfast, isFavorite: true)) { _ in }
    }
}

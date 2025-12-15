import SwiftUI

struct PresetsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText: String = ""
    @State private var selectedCategory: Category?
    @State private var isPresentingEditor = false
    @State private var editingPreset: Preset?

    private var filteredPresets: [Preset] {
        store.presets.filter { preset in
            let matchesCategory = selectedCategory == nil || preset.category == selectedCategory
            let matchesSearch = searchText.isEmpty || preset.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var groupedPresets: [(Category, [Preset])] {
        Category.allCases.map { category in
            (category, filteredPresets.filter { $0.category == category })
        }
    }

    private var hasPresets: Bool {
        groupedPresets.contains { !$0.1.isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                categoryChips

                if !hasPresets {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No presets found")
                            .font(.headline)
                        Text("Try adjusting your search or filters.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }

                List {
                    ForEach(groupedPresets, id: \.0) { category, presets in
                        Section(header: Text(category.displayName)) {
                            if presets.isEmpty {
                                Text("No presets yet")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(presets) { preset in
                                    PresetRowView(preset: preset) {
                                        store.toggleFavorite(for: preset)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingPreset = preset
                                        isPresentingEditor = true
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            store.deletePreset(preset)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
            .padding(.top, 8)
            .navigationTitle("Presets")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingPreset = nil
                        isPresentingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search presets")
        .sheet(isPresented: $isPresentingEditor, onDismiss: { editingPreset = nil }) {
            PresetEditorView(preset: editingPreset) { updatedPreset in
                if editingPreset != nil {
                    store.updatePreset(updatedPreset)
                } else {
                    store.addPreset(updatedPreset)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryChip(for: nil, label: "All")
                ForEach(Category.allCases) { category in
                    categoryChip(for: category, label: category.displayName, systemImage: category.icon)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func categoryChip(for category: Category?, label: String, systemImage: String? = nil) -> some View {
        let isSelected = category == selectedCategory
        Button {
            selectedCategory = isSelected ? nil : category
        } label: {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(label)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(isSelected ? Theme.accent.opacity(0.2) : Color(.systemGray6))
            .foregroundStyle(isSelected ? Theme.accent : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PresetsView()
        .environmentObject(AppStore())
}

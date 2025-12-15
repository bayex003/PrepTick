import Foundation
import SwiftUI

enum Category: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case beverage
    case dessert
    case prep

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .beverage: return "Beverage"
        case .dessert: return "Dessert"
        case .prep: return "Prep"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "fork.knife"
        case .dinner: return "moon.stars.fill"
        case .beverage: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        case .prep: return "timer"
        }
    }
}

struct Preset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var durationSeconds: Int
    var category: Category
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, durationSeconds: Int, category: Category, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.category = category
        self.isFavorite = isFavorite
    }

    enum CodingKeys: CodingKey {
        case id
        case name
        case durationSeconds
        case category
        case isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        category = try container.decode(Category.self, forKey: .category)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }

    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = durationSeconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(durationSeconds)) ?? "\(durationSeconds / 60)m"
    }
}

struct RunningTimer: Identifiable, Codable, Equatable {
    let id: UUID
    var preset: Preset
    var startedAt: Date
    var endAt: Date
    var pausedRemainingSeconds: Int?

    init(id: UUID = UUID(), preset: Preset, startedAt: Date = .now, endAt: Date, pausedRemainingSeconds: Int? = nil) {
        self.id = id
        self.preset = preset
        self.startedAt = startedAt
        self.endAt = endAt
        self.pausedRemainingSeconds = pausedRemainingSeconds
    }

    var isPaused: Bool { pausedRemainingSeconds != nil }

    var remainingSeconds: Int {
        remainingSeconds(at: .now)
    }

    func remainingSeconds(at date: Date) -> Int {
        if let pausedRemainingSeconds {
            return max(0, pausedRemainingSeconds)
        }

        return max(0, Int(endAt.timeIntervalSince(date)))
    }

    private enum CodingKeys: CodingKey {
        case id
        case preset
        case startedAt
        case endAt
        case remainingSeconds
        case pausedRemainingSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        preset = try container.decode(Preset.self, forKey: .preset)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        pausedRemainingSeconds = try container.decodeIfPresent(Int.self, forKey: .pausedRemainingSeconds)

        if let endAt = try container.decodeIfPresent(Date.self, forKey: .endAt) {
            self.endAt = endAt
        } else if let remainingSeconds = try container.decodeIfPresent(Int.self, forKey: .remainingSeconds) {
            endAt = startedAt.addingTimeInterval(TimeInterval(remainingSeconds))
        } else {
            endAt = startedAt
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(preset, forKey: .preset)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(endAt, forKey: .endAt)
        try container.encodeIfPresent(pausedRemainingSeconds, forKey: .pausedRemainingSeconds)
    }
}

struct Settings: Codable, Equatable {
    var notificationsEnabled: Bool
    var accentColorHex: String

    init(notificationsEnabled: Bool = true, accentColorHex: String = "#88A096") {
        self.notificationsEnabled = notificationsEnabled
        self.accentColorHex = accentColorHex
    }

    var accentColor: Color { Color(hex: accentColorHex) }
}

struct LastSet: Identifiable, Codable, Equatable {
    let id: UUID
    var presetID: UUID
    var setAt: Date

    init(id: UUID = UUID(), presetID: UUID, setAt: Date = .now) {
        self.id = id
        self.presetID = presetID
        self.setAt = setAt
    }
}

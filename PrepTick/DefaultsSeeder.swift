import Foundation

struct DefaultsSeeder {
    static func seedPresets() -> [Preset] {
        let defaults: [(String, Int, Category, Bool)] = [
            ("Soft Boiled Eggs", 360, .breakfast, true),
            ("Hard Boiled Eggs", 600, .breakfast, false),
            ("Overnight Oats", 300, .breakfast, false),
            ("French Press Coffee", 240, .beverage, true),
            ("Drip Coffee Warm", 300, .beverage, false),
            ("Iced Tea Brew", 900, .beverage, false),
            ("Pasta Al Dente", 480, .lunch, true),
            ("Rice (Jasmine)", 900, .lunch, false),
            ("Quinoa", 960, .lunch, false),
            ("Roast Chicken Rest", 900, .dinner, false),
            ("Steak Rest", 420, .dinner, true),
            ("Salmon Bake", 720, .dinner, false),
            ("Brownies", 1500, .dessert, false),
            ("Cookies", 720, .dessert, true),
            ("Cheesecake Chill", 14400, .dessert, false),
            ("Marinade", 3600, .prep, false),
            ("Dough Proof", 7200, .prep, false),
            ("Preheat Oven", 600, .prep, true)
        ]

        return defaults.map { Preset(name: $0.0, durationSeconds: $0.1, category: $0.2, isFavorite: $0.3) }
    }
}

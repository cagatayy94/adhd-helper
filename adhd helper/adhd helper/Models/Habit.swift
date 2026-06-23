import Foundation

struct Habit: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var description: String
    var icon: String // Emoji character
    var colorHex: String // Hex color representation
    var dailyGoal: Int = 1 // How many times per day
    var repeatInterval: RepeatInterval = .daily
    var duration: String = "5 min" // e.g., "5 min" or "1 hour"
    var date: Date = Date() // Associated date / start date
    var excludedDates: [String] = [] // Keys of dates where this habit was deleted
}

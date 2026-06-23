import Foundation

struct DailyLog: Codable, Equatable {
    // Map of Habit ID String (UUID) to completion count for that day
    var completions: [String: Int] = [:]
    var screenTimeLimitMinutes: Int = 180
    var categoryMinutes: [String: Int] = [:]

    enum CodingKeys: String, CodingKey {
        case completions
        case screenTimeLimitMinutes
        case categoryMinutes
    }

    init(completions: [String: Int] = [:], screenTimeLimitMinutes: Int = 180, categoryMinutes: [String: Int] = [:]) {
        self.completions = completions
        self.screenTimeLimitMinutes = screenTimeLimitMinutes
        self.categoryMinutes = categoryMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.completions = try container.decodeIfPresent([String: Int].self, forKey: .completions) ?? [:]
        self.screenTimeLimitMinutes = try container.decodeIfPresent(Int.self, forKey: .screenTimeLimitMinutes) ?? 180
        self.categoryMinutes = try container.decodeIfPresent([String: Int].self, forKey: .categoryMinutes) ?? [:]
    }
}

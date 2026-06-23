import SwiftUI
import Combine
import FamilyControls

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date() {
        didSet {
            let calendar = Calendar.current
            if !calendar.isDate(selectedDate, equalTo: currentMonth, toGranularity: .month) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentMonth = selectedDate
                }
            }
        }
    } // Defaults to today
    @Published var habits: [Habit] = []
    @Published var dailyLogs: [String: DailyLog] = [:]
    @Published var appLimits: [AppLimit] = []
    
    let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
    }
    
    init() {
        loadHabits()
        loadLogs()
        loadAppLimits()
    }
    
    // MARK: - Actions & Intents
    
    func selectDay(_ day: CalendarDay) {
        // Log to console as requested by the user: "when click console log clicked"
        print("clicked")
        print("Clicked day: \(day.date.formatted(date: .numeric, time: .omitted)) (isCurrentMonth: \(day.isCurrentMonth))")
        
        triggerHapticFeedback()
        
        withAnimation(.easeOut(duration: 0.2)) {
            selectedDate = day.date
            if !day.isCurrentMonth {
                currentMonth = day.date
            }
        }
    }
    
    func previousMonth() {
        triggerHapticFeedback()
        withAnimation(.easeInOut(duration: 0.25)) {
            if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                currentMonth = newDate
            }
        }
    }
    
    func nextMonth() {
        triggerHapticFeedback()
        withAnimation(.easeInOut(duration: 0.25)) {
            if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                currentMonth = newDate
            }
        }
    }
    
    func goToToday() {
        triggerHapticFeedback()
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = Date()
            selectedDate = Date()
        }
    }
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Habit Logic
    
    func addHabit(
        title: String,
        description: String,
        icon: String,
        colorHex: String,
        dailyGoal: Int,
        repeatInterval: RepeatInterval,
        duration: String,
        date: Date
    ) {
        let newHabit = Habit(
            title: title,
            description: description,
            icon: icon,
            colorHex: colorHex,
            dailyGoal: dailyGoal,
            repeatInterval: repeatInterval,
            duration: duration,
            date: date
        )
        habits.append(newHabit)
        saveHabits()
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }
    
    func excludeHabit(_ habit: Habit, on date: Date) {
        let key = keyFormatter.string(from: date)
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habits[index]
            if !updatedHabit.excludedDates.contains(key) {
                updatedHabit.excludedDates.append(key)
            }
            habits[index] = updatedHabit
            saveHabits()
        }
    }
    
    func isHabitActive(_ habit: Habit, on date: Date) -> Bool {
        let key = keyFormatter.string(from: date)
        if habit.excludedDates.contains(key) {
            return false
        }
        
        let calendar = Calendar.current
        let startOfDayHabit = calendar.startOfDay(for: habit.date)
        let startOfDayTarget = calendar.startOfDay(for: date)
        
        guard startOfDayTarget >= startOfDayHabit else { return false }
        
        switch habit.repeatInterval {
        case .once:
            return calendar.isDate(habit.date, inSameDayAs: date)
        case .daily:
            return true
        case .weekly:
            let habitWeekday = calendar.component(.weekday, from: habit.date)
            let targetWeekday = calendar.component(.weekday, from: date)
            return habitWeekday == targetWeekday
        case .monthly:
            let habitDay = calendar.component(.day, from: habit.date)
            let targetDay = calendar.component(.day, from: date)
            return habitDay == targetDay
        }
    }
    
    func getProgress(for habit: Habit, on date: Date) -> Int {
        let key = keyFormatter.string(from: date)
        let log = dailyLogs[key] ?? DailyLog()
        return log.completions[habit.id.uuidString] ?? 0
    }
    
    func updateProgress(for habit: Habit, on date: Date, progress: Int) {
        let key = keyFormatter.string(from: date)
        var log = dailyLogs[key] ?? DailyLog()
        log.completions[habit.id.uuidString] = progress
        dailyLogs[key] = log
        saveLogs()
    }
    
    // MARK: - Screen Time Logic
    
    func getScreenTimeLimit(for date: Date) -> Int {
        let key = keyFormatter.string(from: date)
        let log = dailyLogs[key] ?? DailyLog()
        return log.screenTimeLimitMinutes
    }
    
    func setScreenTimeLimit(for date: Date, limit: Int) {
        let key = keyFormatter.string(from: date)
        var log = dailyLogs[key] ?? DailyLog()
        log.screenTimeLimitMinutes = limit
        dailyLogs[key] = log
        saveLogs()
    }
    
    func getCategoryMinutes(for date: Date, category: String) -> Int {
        let key = keyFormatter.string(from: date)
        let log = dailyLogs[key] ?? DailyLog()
        return log.categoryMinutes[category] ?? 0
    }
    
    func updateCategoryMinutes(for date: Date, category: String, minutes: Int) {
        let key = keyFormatter.string(from: date)
        var log = dailyLogs[key] ?? DailyLog()
        log.categoryMinutes[category] = max(0, minutes)
        dailyLogs[key] = log
        saveLogs()
    }
    
    func getTotalScreenTime(for date: Date) -> Int {
        let key = keyFormatter.string(from: date)
        let log = dailyLogs[key] ?? DailyLog()
        return log.categoryMinutes.values.reduce(0, +)
    }
    
    // MARK: - App Limit Logic
    
    private let appGroupSuiteName = "group.com.caca.adhd-helper"
    
    private func getUserDefaults() -> UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? UserDefaults.standard
    }
    
    func addAppLimit(title: String, selection: FamilyActivitySelection, threshold: String) {
        let limit = AppLimit(title: title, selection: selection, threshold: threshold)
        appLimits.append(limit)
        saveAppLimits()
        
        // Start monitoring
        FamilyControlsManager.shared.startMonitoring(limit: limit)
    }
    
    func deleteAppLimit(_ limit: AppLimit) {
        appLimits.removeAll { $0.id == limit.id }
        saveAppLimits()
        
        // Stop monitoring
        FamilyControlsManager.shared.stopMonitoring(limit: limit)
    }
    
    func toggleAppLimit(_ limit: AppLimit) {
        if let index = appLimits.firstIndex(where: { $0.id == limit.id }) {
            appLimits[index].isActive.toggle()
            let updatedLimit = appLimits[index]
            saveAppLimits()
            
            if updatedLimit.isActive {
                FamilyControlsManager.shared.startMonitoring(limit: updatedLimit)
            } else {
                FamilyControlsManager.shared.stopMonitoring(limit: updatedLimit)
            }
        }
    }
    
    private func saveAppLimits() {
        let limitsToSave = appLimits
        let defaults = getUserDefaults()
        Task.detached(priority: .background) {
            do {
                let encoded = try JSONEncoder().encode(limitsToSave)
                defaults.set(encoded, forKey: "ADHDAppLimits")
            } catch {
                print("Failed to save app limits: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadAppLimits() {
        let defaults = getUserDefaults()
        if let data = defaults.data(forKey: "ADHDAppLimits"),
           let decoded = try? JSONDecoder().decode([AppLimit].self, from: data) {
            self.appLimits = decoded
        } else {
            self.appLimits = []
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveHabits() {
        let habitsToSave = habits
        Task.detached(priority: .background) {
            do {
                let encoded = try JSONEncoder().encode(habitsToSave)
                UserDefaults.standard.set(encoded, forKey: "ADHDHabitsList")
            } catch {
                print("Failed to save habits list: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: "ADHDHabitsList"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            self.habits = decoded
        } else {
            // Default setup for first run
            let today = Date()
            self.habits = [
                Habit(title: "Medication", description: "Log your daily ADHD medication", icon: "💊", colorHex: "#007AFF", dailyGoal: 1, repeatInterval: .daily, duration: "1 min", date: today),
                Habit(title: "Drink Water", description: "Stay hydrated throughout the day", icon: "💧", colorHex: "#32ADE6", dailyGoal: 4, repeatInterval: .daily, duration: "2 min", date: today),
                Habit(title: "15-Min Exercise", description: "Boost dopamine and mood", icon: "🏃", colorHex: "#34C759", dailyGoal: 1, repeatInterval: .daily, duration: "15 min", date: today),
                Habit(title: "Mindful Break", description: "5 minutes of quiet resting", icon: "🧘", colorHex: "#AF52DE", dailyGoal: 1, repeatInterval: .daily, duration: "5 min", date: today)
            ]
            saveHabits()
        }
    }
    
    private func saveLogs() {
        let logsToSave = dailyLogs
        Task.detached(priority: .background) {
            do {
                let encoded = try JSONEncoder().encode(logsToSave)
                UserDefaults.standard.set(encoded, forKey: "ADHDDailyLogs")
            } catch {
                print("Failed to save daily logs: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadLogs() {
        guard let data = UserDefaults.standard.data(forKey: "ADHDDailyLogs") else { return }
        do {
            let decoded = try JSONDecoder().decode([String: DailyLog].self, from: data)
            self.dailyLogs = decoded
        } catch {
            print("Failed to load daily logs, resetting database: \(error.localizedDescription)")
            self.dailyLogs = [:]
            saveLogs()
        }
    }
}

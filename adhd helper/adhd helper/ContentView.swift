//
//  ContentView.swift
//  adhd helper
//
//  Created by Çağatay Yılmaz on 28.05.2026.
//

import SwiftUI
import Combine

// MARK: - Enums & Models

enum RepeatInterval: String, Codable, CaseIterable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

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

struct CalendarDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
}

struct DailyLog: Codable, Equatable {
    // Map of Habit ID String (UUID) to completion count for that day
    var completions: [String: Int] = [:]
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Calendar Helpers

extension Calendar {
    /// Generates exactly 42 days (6 weeks) representing the monthly calendar grid for the specified date.
    func generateDaysInMonth(for date: Date) -> [CalendarDay] {
        guard let firstOfMonth = self.firstDayOfMonth(for: date) else { return [] }
        
        let firstWeekday = self.component(.weekday, from: firstOfMonth)
        let firstWeekdayIndex = (firstWeekday - self.firstWeekday + 7) % 7
        
        guard let startDate = self.date(byAdding: .day, value: -firstWeekdayIndex, to: firstOfMonth) else { return [] }
        
        var days: [CalendarDay] = []
        for i in 0..<42 {
            if let dayDate = self.date(byAdding: .day, value: i, to: startDate) {
                let isCurrentMonth = self.isDate(dayDate, equalTo: date, toGranularity: .month)
                let isToday = self.isDateInToday(dayDate)
                days.append(CalendarDay(date: dayDate, isCurrentMonth: isCurrentMonth, isToday: isToday))
            }
        }
        return days
    }
    
    private func firstDayOfMonth(for date: Date) -> Date? {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
}

// MARK: - View Model

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

// MARK: - Main View

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.secondarySystemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        HeaderView()
                        
                        CalendarCardView(viewModel: viewModel)
                        
                        TrackerCardView(viewModel: viewModel)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Subviews

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mindful Days")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your ADHD Companion Calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 28))
                .foregroundColor(.indigo)
                .padding(10)
                .background(Color.indigo.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}

struct CalendarCardView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Month & Navigation Header
            HStack {
                Text(viewModel.monthYearFormatter.string(from: viewModel.currentMonth))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .animation(.none, value: viewModel.currentMonth)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { viewModel.previousMonth() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.indigo)
                            .frame(width: 36, height: 36)
                            .background(Color.indigo.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { viewModel.goToToday() }) {
                        Text("Today")
                            .font(.system(.footnote, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.indigo)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(Color.indigo.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: { viewModel.nextMonth() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.indigo)
                            .frame(width: 36, height: 36)
                            .background(Color.indigo.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid
            let days = Calendar.current.generateDaysInMonth(for: viewModel.currentMonth)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(days) { day in
                    let isSelected = Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate)
                    let completedHabitsForDay = viewModel.habits.filter { habit in
                        let progress = viewModel.getProgress(for: habit, on: day.date)
                        return progress >= habit.dailyGoal
                    }
                    
                    CalendarDayButton(
                        day: day,
                        isSelected: isSelected,
                        completedHabits: completedHabitsForDay,
                        dayFormatter: viewModel.dayFormatter,
                        action: { viewModel.selectDay(day) }
                    )
                }
            }
            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

struct CalendarDayButton: View {
    let day: CalendarDay
    let isSelected: Bool
    let completedHabits: [Habit]
    let dayFormatter: DateFormatter
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: day.date))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(day.isToday ? .bold : .regular)
                    .foregroundColor(dayTextColor)
                    .frame(width: 36, height: 36)
                    .background(dayBackground)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.indigo, lineWidth: (day.isToday && !isSelected) ? 2 : 0)
                    )
                
                // Activity Indicator dots
                HStack(spacing: 3) {
                    ForEach(completedHabits.prefix(4)) { habit in
                        Circle()
                            .fill(Color(hex: habit.colorHex))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dayTextColor: Color {
        if isSelected {
            return .white
        } else if !day.isCurrentMonth {
            return .secondary.opacity(0.4)
        } else if day.isToday {
            return .indigo
        } else {
            return .primary
        }
    }
    
    private var dayBackground: Color {
        isSelected ? .indigo : .clear
    }
}

struct TrackerCardView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var showAddHabitSheet = false
    @State private var showDeleteConfirmation = false
    @State private var habitToDelete: Habit? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                DatePicker(
                    "Tracked Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                
                Spacer()
                
                Button(action: { showAddHabitSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.indigo)
                }
            }
            .padding(.bottom, 4)
            
            let activeHabits = viewModel.habits.filter { viewModel.isHabitActive($0, on: viewModel.selectedDate) }
            
            if activeHabits.isEmpty {
                VStack(spacing: 12) {
                    Text(viewModel.habits.isEmpty ? "No Habits Tracked" : "No Active Habits Today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.habits.isEmpty ? "Tap the + button to add custom habits." : "No habits scheduled for this day.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(activeHabits) { habit in
                        let progress = viewModel.getProgress(for: habit, on: viewModel.selectedDate)
                        
                        CheckinRow(
                            title: habit.title,
                            subtitle: habit.description,
                            emoji: habit.icon,
                            color: Color(hex: habit.colorHex),
                            progress: progress,
                            dailyGoal: habit.dailyGoal,
                            repeatInterval: habit.repeatInterval.rawValue,
                            duration: habit.duration,
                            action: {
                                let nextProgress = (progress + 1) % (habit.dailyGoal + 1)
                                viewModel.updateProgress(for: habit, on: viewModel.selectedDate, progress: nextProgress)
                            }
                        )
                        .swipeToDelete {
                            viewModel.triggerHapticFeedback()
                            habitToDelete = habit
                            showDeleteConfirmation = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.triggerHapticFeedback()
                                habitToDelete = habit
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Habit", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showAddHabitSheet) {
            AddHabitSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            "Delete Habit",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete this day only") {
                if let habit = habitToDelete {
                    viewModel.excludeHabit(habit, on: viewModel.selectedDate)
                }
            }
            
            Button("Delete all occurrences", role: .destructive) {
                if let habit = habitToDelete {
                    viewModel.deleteHabit(habit)
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to delete this habit only for today or delete all recurring instances?")
        }
    }
}

struct CheckinRow: View {
    let title: String
    let subtitle: String
    let emoji: String
    let color: Color
    let progress: Int
    let dailyGoal: Int
    let repeatInterval: String
    let duration: String
    let action: () -> Void
    
    var isCompleted: Bool {
        progress >= dailyGoal
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(isCompleted ? color.opacity(0.2) : Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    Text("⏱ \(duration)")
                    Text("•")
                    Text("🔄 \(repeatInterval)")
                }
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .scaleEffect(1.1)
            } else if progress > 0 {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    Text("\(progress)/\(dailyGoal)")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
            } else {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    Text("\(dailyGoal)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .padding(12)
        .contentShape(Rectangle()) // Make the entire row area tap-responsive (even empty spaces)
        .onTapGesture {
            action()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCompleted ? color.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? color.opacity(0.15) : Color(.separator), lineWidth: 1)
        )
    }
}

// MARK: - Add Habit Sheet

struct AddHabitSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CalendarViewModel
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var icon: String = "💊"
    @State private var selectedColorHex: String = "#007AFF"
    @State private var dailyGoal: Int = 1
    @State private var repeatInterval: RepeatInterval = .daily
    @State private var duration: String = "5 min"
    @State private var date: Date
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        // Default the form date to the currently selected calendar date
        self._date = State(initialValue: viewModel.selectedDate)
    }
    
    private let presetEmojis = ["💊", "💧", "🏃", "🧘", "📚", "🍏", "☕️", "🛌", "🧹", "🧠", "🎯", "🚶", "📓", "🥦"]
    
    private let curatedColorsHex = [
        "#007AFF", // Blue
        "#32ADE6", // Cyan
        "#34C759", // Green
        "#AF52DE", // Purple
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FF2D55"  // Pink
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Details")) {
                    TextField("Habit Title (e.g. Meds)", text: $title)
                    TextField("Description (e.g. Focus booster)", text: $description)
                }
                
                Section(header: Text("Date & Schedule")) {
                    DatePicker("Start/Target Date", selection: $date, displayedComponents: [.date])
                    
                    Stepper("Daily Goal: \(dailyGoal) \(dailyGoal == 1 ? "time" : "times")", value: $dailyGoal, in: 1...20)
                    
                    Picker("Repeat Interval", selection: $repeatInterval) {
                        ForEach(RepeatInterval.allCases, id: \.self) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    
                    TextField("Duration (e.g. 5 min)", text: $duration)
                }
                
                Section(header: Text("Style & Icon")) {
                    // Emoji Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Icon Emoji")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(presetEmojis, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.title2)
                                        .padding(8)
                                        .background(icon == emoji ? Color.indigo.opacity(0.2) : Color.clear)
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            viewModel.triggerHapticFeedback()
                                            icon = emoji
                                        }
                                }
                            }
                        }
                    }
                    
                    // Color Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Theme Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(curatedColorsHex, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        viewModel.triggerHapticFeedback()
                                        selectedColorHex = hex
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addHabit(
                            title: title,
                            description: description,
                            icon: icon,
                            colorHex: selectedColorHex,
                            dailyGoal: dailyGoal,
                            repeatInterval: repeatInterval,
                            duration: duration,
                            date: date
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}

// MARK: - Swipe to Delete custom gesture modifier

struct SwipeToDeleteModifier: ViewModifier {
    let onDelete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            // Delete Action Background
            Button(action: {
                withAnimation(.spring()) {
                    offset = 0
                    isSwiped = false
                }
                onDelete()
            }) {
                ZStack {
                    Color.red
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(width: 80)
                .cornerRadius(16)
            }
            .padding(.vertical, 1)
            
            content
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                let target = isSwiped ? -80 + value.translation.width : value.translation.width
                                offset = max(target, -100)
                            } else if isSwiped && value.translation.width > 0 {
                                offset = -80 + value.translation.width
                                offset = min(offset, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if value.translation.width < -40 {
                                    offset = -80
                                    isSwiped = true
                                } else {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        }
    }
}

extension View {
    func swipeToDelete(onDelete: @escaping () -> Void) -> some View {
        self.modifier(SwipeToDeleteModifier(onDelete: onDelete))
    }
}

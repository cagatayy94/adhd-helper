import SwiftUI

struct TrackerCardView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var showAddHabitSheet = false
    @State private var showDeleteConfirmation = false
    @State private var habitToDelete: Habit? = nil
    
    var body: some View {
        VStack(spacing: 18) {
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
    
    private let presetEmojis = ["💊", "💧", "🏃", "🧘", "📚", "🍏", "☕️", "🛌", "🧹", "🧠", "🎯", "🚶", "📓", "🥦", "🪥", "🐦", "🐱"]
    
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

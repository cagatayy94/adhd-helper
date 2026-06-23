import SwiftUI

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

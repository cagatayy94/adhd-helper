import Foundation

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

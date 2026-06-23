import Testing
import Foundation
import FamilyControls
@testable import adhd_helper

struct adhd_helperTests {

    @Test func testCalendarGridGenerationLength() async throws {
        let calendar = Calendar.current
        let today = Date()
        let days = calendar.generateDaysInMonth(for: today)
        
        // The calendar grid must always return exactly 42 days (6 weeks * 7 days)
        #expect(days.count == 42)
    }

    @Test func testCalendarGridGenerationContainsCurrentMonth() async throws {
        let calendar = Calendar.current
        
        // Define a specific date: June 15, 2026
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 15
        
        guard let testDate = calendar.date(from: components) else {
            Issue.record("Failed to create test date")
            return
        }
        
        let days = calendar.generateDaysInMonth(for: testDate)
        
        // Confirm at least one day in the grid is June 1st, 2026
        let hasJuneFirst = days.contains { day in
            let comps = calendar.dateComponents([.year, .month, .day], from: day.date)
            return comps.year == 2026 && comps.month == 6 && comps.day == 1
        }
        #expect(hasJuneFirst)
        
        // Confirm at least one day in the grid is June 30th, 2026
        let hasJuneThirtieth = days.contains { day in
            let comps = calendar.dateComponents([.year, .month, .day], from: day.date)
            return comps.year == 2026 && comps.month == 6 && comps.day == 30
        }
        #expect(hasJuneThirtieth)
        
        // Confirm all June days are marked as isCurrentMonth == true
        for day in days {
            let comps = calendar.dateComponents([.year, .month], from: day.date)
            if comps.year == 2026 && comps.month == 6 {
                #expect(day.isCurrentMonth == true)
            } else {
                #expect(day.isCurrentMonth == false)
            }
        }
    }

    @Test func testExcludeHabitSingleDay() async throws {
        await MainActor.run {
            let viewModel = CalendarViewModel()
            viewModel.habits = [] // Reset for isolation
            
            let today = Date()
            viewModel.addHabit(
                title: "Test Habit",
                description: "Test Desc",
                icon: "💊",
                colorHex: "#007AFF",
                dailyGoal: 1,
                repeatInterval: .daily,
                duration: "5 min",
                date: today
            )
            
            guard let habit = viewModel.habits.first else {
                Issue.record("Failed to create habit")
                return
            }
            
            // Should be active today
            #expect(viewModel.isHabitActive(habit, on: today) == true)
            
            // Exclude for today
            viewModel.excludeHabit(habit, on: today)
            
            guard let updatedHabit = viewModel.habits.first else {
                Issue.record("Failed to find updated habit")
                return
            }
            
            // Should NOT be active today
            #expect(viewModel.isHabitActive(updatedHabit, on: today) == false)
            
            // Should still be active tomorrow
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            #expect(viewModel.isHabitActive(updatedHabit, on: tomorrow) == true)
        }
    }

    @Test func testScreenTimeLoggingAndLimits() async throws {
        await MainActor.run {
            let viewModel = CalendarViewModel()
            let today = Date()
            
            // Check default limit
            let defaultLimit = viewModel.getScreenTimeLimit(for: today)
            #expect(defaultLimit == 180)
            
            // Modify limit
            viewModel.setScreenTimeLimit(for: today, limit: 120)
            #expect(viewModel.getScreenTimeLimit(for: today) == 120)
            
            // Check categories start at 0
            let socialMinutes = viewModel.getCategoryMinutes(for: today, category: "Social")
            #expect(socialMinutes == 0)
            
            // Update category minutes
            viewModel.updateCategoryMinutes(for: today, category: "Social", minutes: 45)
            #expect(viewModel.getCategoryMinutes(for: today, category: "Social") == 45)
            #expect(viewModel.getTotalScreenTime(for: today) == 45)
            
            // Update another category
            viewModel.updateCategoryMinutes(for: today, category: "Gaming", minutes: 30)
            #expect(viewModel.getTotalScreenTime(for: today) == 75)
            
            // Check negative values are capped at 0
            viewModel.updateCategoryMinutes(for: today, category: "Gaming", minutes: -15)
            #expect(viewModel.getCategoryMinutes(for: today, category: "Gaming") == 0)
        }
    }

    @Test func testAppLimitsAddingAndToggling() async throws {
        await MainActor.run {
            let viewModel = CalendarViewModel()
            viewModel.appLimits = [] // Clear for isolation
            
            let selection = FamilyActivitySelection()
            viewModel.addAppLimit(title: "Block Roblox", selection: selection, threshold: "1h")
            #expect(viewModel.appLimits.count == 1)
            #expect(viewModel.appLimits.first?.title == "Block Roblox")
            #expect(viewModel.appLimits.first?.threshold == "1h")
            #expect(viewModel.appLimits.first?.isActive == true)
            
            guard let limit = viewModel.appLimits.first else {
                Issue.record("Failed to add limit")
                return
            }
            
            viewModel.toggleAppLimit(limit)
            #expect(viewModel.appLimits.first?.isActive == false)
            
            viewModel.deleteAppLimit(limit)
            #expect(viewModel.appLimits.isEmpty == true)
        }
    }
}


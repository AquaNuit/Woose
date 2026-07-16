//
//  JournalView.swift
//  BevelClone
//
//  90-day habit tracking calendar
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header stats
                    statsSection
                    
                    // 90-day calendar heatmap
                    calendarHeatmap
                    
                    // Today's habits
                    todayHabitsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.08, green: 0.06, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Streak",
                value: "\(calculateStreak())",
                unit: "days",
                color: .orange
            )
            
            StatCard(
                title: "This Week",
                value: "\(completedThisWeek())",
                unit: "habits",
                color: .green
            )
            
            StatCard(
                title: "Total",
                value: "\(viewModel.journalEntries.count)",
                unit: "days",
                color: .blue
            )
        }
    }
    
    // MARK: - Calendar Heatmap
    
    private var calendarHeatmap: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("90-Day Activity")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                // Simple grid representation (full heatmap visualization would be more complex)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(0..<90, id: \.self) { index in
                        let calendar = Calendar.current
                        let date = calendar.date(byAdding: .day, value: -89 + index, to: Date()) ?? Date()
                        let entry = viewModel.journalEntries.first { calendar.isDate($0.date, inSameDayAs: date) }
                        let completed = entry?.completedHabitsCount ?? 0
                        
                        Rectangle()
                            .fill(heatmapColor(completed: completed))
                            .frame(height: 8)
                            .cornerRadius(2)
                    }
                }
                
                // Legend
                HStack {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { level in
                            Rectangle()
                                .fill(heatmapColor(completed: level * 3))
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                        }
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Spacer()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Today's Habits
    
    private var todayHabitsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Habits")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if let todayEntry = viewModel.journalEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
                    VStack(spacing: 12) {
                        HabitRow(habit: .steps10k, isCompleted: todayEntry.steps10k, isAutomatic: true)
                        HabitRow(habit: .cardio20min, isCompleted: todayEntry.cardio20min, isAutomatic: true)
                        HabitRow(habit: .strength20min, isCompleted: todayEntry.strength20min, isAutomatic: true)
                        HabitRow(habit: .hydration, isCompleted: todayEntry.hydration, isAutomatic: false)
                        HabitRow(habit: .caffeine, isCompleted: todayEntry.caffeine, isAutomatic: false)
                        HabitRow(habit: .deviceInBed, isCompleted: todayEntry.deviceInBed, isAutomatic: false)
                    }
                } else {
                    Text("No habits logged for today")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateStreak() -> Int {
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for _ in 0..<90 {
            if let entry = viewModel.journalEntries.first(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }),
               entry.completedHabitsCount > 0 {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func completedThisWeek() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return viewModel.journalEntries
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.completedHabitsCount }
    }
    
    private func heatmapColor(completed: Int) -> Color {
        switch completed {
        case 0: return .white.opacity(0.1)
        case 1...3: return .green.opacity(0.3)
        case 4...6: return .green.opacity(0.5)
        case 7...9: return .green.opacity(0.7)
        default: return .green
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Habit Row

struct HabitRow: View {
    let habit: JournalHabit
    let isCompleted: Bool
    let isAutomatic: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isCompleted ? .green : .white.opacity(0.3))
            
            Text(habit.rawValue)
                .font(.body)
                .foregroundStyle(.white)
            
            Spacer()
            
            if isAutomatic {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.yellow.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyMetrics.self, JournalEntry.self, FitnessVolume.self, configurations: config)
    let context = container.mainContext
    let viewModel = AppViewModel(isMocked: true, modelContext: context)
    
    JournalView(viewModel: viewModel)
}

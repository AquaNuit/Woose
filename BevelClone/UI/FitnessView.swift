//
//  FitnessView.swift
//  BevelClone
//
//  30-day activity grid and strength volume tracking
//

import SwiftUI

struct FitnessView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 30-day activity heatmap
                    activityHeatmap
                    
                    // Strength volume breakdown
                    strengthVolumeSection
                    
                    // Cardio load
                    cardioLoadCard
                    
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
            .navigationTitle("Fitness")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Activity Heatmap
    
    private var activityHeatmap: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("30-Day Activity")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                // 5 weeks × 7 days grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(0..<35, id: \.self) { index in
                        let calendar = Calendar.current
                        let date = calendar.date(byAdding: .day, value: -34 + index, to: Date()) ?? Date()
                        let volume = viewModel.fitnessVolumes.first { calendar.isDate($0.date, inSameDayAs: date) }
                        let workoutCount = volume?.workoutCount ?? 0
                        
                        VStack(spacing: 4) {
                            Text(dayLabel(for: date))
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(workoutColor(count: workoutCount))
                                .frame(height: 40)
                                .overlay(
                                    Text(workoutCount > 0 ? "\(workoutCount)" : "")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                )
                        }
                    }
                }
                
                // Legend
                HStack {
                    ForEach(0..<4) { level in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(workoutColor(count: level))
                                .frame(width: 16, height: 16)
                            
                            Text(level == 0 ? "Rest" : "\(level)")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Strength Volume
    
    private var strengthVolumeSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Strength Volume (7 Days)")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                let weekVolumes = calculateWeeklyVolumes()
                
                VStack(spacing: 12) {
                    MuscleGroupBar(muscleGroup: .chest, sets: weekVolumes[.chest] ?? 0)
                    MuscleGroupBar(muscleGroup: .back, sets: weekVolumes[.back] ?? 0)
                    MuscleGroupBar(muscleGroup: .shoulders, sets: weekVolumes[.shoulders] ?? 0)
                    MuscleGroupBar(muscleGroup: .arms, sets: weekVolumes[.arms] ?? 0)
                    MuscleGroupBar(muscleGroup: .legs, sets: weekVolumes[.legs] ?? 0)
                    MuscleGroupBar(muscleGroup: .core, sets: weekVolumes[.core] ?? 0)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Cardio Load
    
    private var cardioLoadCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Cardio Load (7 Days)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                }
                
                let weeklyCardioLoad = calculateWeeklyCardioLoad()
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", weeklyCardioLoad))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("units")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                ProgressView(value: min(weeklyCardioLoad / 300, 1.0))
                    .tint(.red)
                    .scaleEffect(y: 2)
            }
            .padding(20)
        }
    }
    
    // MARK: - Helper Functions
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func workoutColor(count: Int) -> Color {
        switch count {
        case 0: return .white.opacity(0.1)
        case 1: return .blue.opacity(0.4)
        case 2: return .blue.opacity(0.7)
        default: return .blue
        }
    }
    
    private func calculateWeeklyVolumes() -> [MuscleGroup: Int] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let recentVolumes = viewModel.fitnessVolumes.filter { $0.date >= weekAgo }
        
        var totals: [MuscleGroup: Int] = [:]
        for group in MuscleGroup.allCases {
            totals[group] = recentVolumes.reduce(0) { $0 + $1.volume(for: group) }
        }
        
        return totals
    }
    
    private func calculateWeeklyCardioLoad() -> Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return viewModel.fitnessVolumes
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.cardioLoad }
    }
}

// MARK: - Muscle Group Bar

struct MuscleGroupBar: View {
    let muscleGroup: MuscleGroup
    let sets: Int
    
    var body: some View {
        HStack {
            Image(systemName: muscleGroup.icon)
                .frame(width: 24)
                .foregroundStyle(.white.opacity(0.7))
            
            Text(muscleGroup.rawValue)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(Double(sets) / 50.0, 1.0))
                        .cornerRadius(4)
                }
            }
            .frame(height: 20)
            
            Text("\(sets)")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyMetrics.self, JournalEntry.self, FitnessVolume.self, configurations: config)
    let context = container.mainContext
    let viewModel = AppViewModel(isMocked: true, modelContext: context)
    
    return FitnessView(viewModel: viewModel)
}

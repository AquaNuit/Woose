//
//  BiologyView.swift
//  BevelClone
//
//  Biological age and biomarker tracking
//

import SwiftUI
import SwiftData

struct BiologyView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Biological Age Hero Card
                    biologicalAgeCard
                    
                    // Biomarkers
                    biomarkersSection
                    
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
            .navigationTitle("Biology")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Biological Age Card
    
    private var biologicalAgeCard: some View {
        GlassCard {
            VStack(spacing: 20) {
                Text("Biological Age")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                
                ZStack {
                    // Background arc
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.white.opacity(0.1), lineWidth: 20)
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(135))
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(135))
                        .animation(.easeInOut(duration: 1.5), value: progressValue)
                    
                    // Age display
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", viewModel.biologicalAge))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("years")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Chronological")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Text(String(format: "%.0f", viewModel.chronologicalAge))
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    
                    Divider()
                        .frame(height: 40)
                        .background(.white.opacity(0.2))
                    
                    VStack(spacing: 4) {
                        Text("Difference")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Text(differenceText)
                            .font(.title2.bold())
                            .foregroundStyle(differenceColor)
                    }
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Biomarkers Section
    
    private var biomarkersSection: some View {
        VStack(spacing: 16) {
            Text("Biomarkers")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let weight = viewModel.weight {
                    BiomarkerCard(
                        title: "Weight",
                        value: String(format: "%.1f", weight),
                        unit: "lbs",
                        icon: "scalemass.fill",
                        color: .blue
                    )
                }
                
                if let bodyFat = viewModel.bodyFatPercentage {
                    BiomarkerCard(
                        title: "Body Fat",
                        value: String(format: "%.1f", bodyFat),
                        unit: "%",
                        icon: "chart.pie.fill",
                        color: .orange
                    )
                }
                
                if let leanMass = viewModel.leanBodyMass {
                    BiomarkerCard(
                        title: "Lean Mass",
                        value: String(format: "%.1f", leanMass),
                        unit: "lbs",
                        icon: "figure.strengthtraining.traditional",
                        color: .green
                    )
                }
                
                if let vo2Max = viewModel.vo2Max {
                    BiomarkerCard(
                        title: "VO₂ Max",
                        value: String(format: "%.1f", vo2Max),
                        unit: "ml/kg/min",
                        icon: "lungs.fill",
                        color: .red
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var progressValue: Double {
        let difference = viewModel.chronologicalAge - viewModel.biologicalAge
        let normalized = (difference + 10) / 20  // Map -10 to +10 range to 0-1
        return min(max(normalized * 0.75, 0), 0.75)  // Clamp to arc range
    }
    
    private var gradientColors: [Color] {
        if viewModel.biologicalAge < viewModel.chronologicalAge {
            return [.green, .cyan]
        } else if viewModel.biologicalAge > viewModel.chronologicalAge {
            return [.orange, .red]
        } else {
            return [.yellow, .orange]
        }
    }
    
    private var differenceText: String {
        let difference = viewModel.chronologicalAge - viewModel.biologicalAge
        if abs(difference) < 0.1 {
            return "±0"
        } else if difference > 0 {
            return String(format: "-%.1f", abs(difference))
        } else {
            return String(format: "+%.1f", abs(difference))
        }
    }
    
    private var differenceColor: Color {
        let difference = viewModel.chronologicalAge - viewModel.biologicalAge
        if abs(difference) < 1 {
            return .yellow
        } else if difference > 0 {
            return .green
        } else {
            return .red
        }
    }
}

// MARK: - Biomarker Card

struct BiomarkerCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    
                    Spacer()
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyMetrics.self, JournalEntry.self, FitnessVolume.self, configurations: config)
    let context = container.mainContext
    let viewModel = AppViewModel(isMocked: true, modelContext: context)
    
    BiologyView(viewModel: viewModel)
}

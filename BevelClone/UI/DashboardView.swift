//
//  DashboardView.swift
//  BevelClone
//
//  Premium glassmorphism dashboard with "The Big Three" metrics
//

import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // The Big Three
                    bigThreeMetrics
                    
                    // Activity Status
                    activityStatusCard
                    
                    // Health Monitor
                    healthMonitorCard
                    
                    // Stress & Energy
                    stressEnergyCard
                    
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Refresh button
            Button {
                Task {
                    await viewModel.forceRefresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - The Big Three
    
    private var bigThreeMetrics: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Strain
                CircularProgressCard(
                    title: "Strain",
                    value: viewModel.strain,
                    color: strainColor(viewModel.strain),
                    icon: "flame.fill"
                )
                
                // Recovery
                CircularProgressCard(
                    title: "Recovery",
                    value: viewModel.recovery,
                    color: recoveryColor(viewModel.recovery),
                    icon: "bolt.heart.fill"
                )
            }
            .frame(height: 180)
            
            // Sleep
            SleepCard(
                hours: viewModel.sleepHours,
                efficiency: viewModel.sleepEfficiency
            )
        }
    }
    
    // MARK: - Activity Status
    
    private var activityStatusCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Text(viewModel.activityStatus.emoji)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Status")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(viewModel.activityStatus.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.bold())
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(20)
        }
    }
    
    // MARK: - Health Monitor
    
    private var healthMonitorCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Health Monitor")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(.red.opacity(0.8))
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    if let rhr = viewModel.currentRHR {
                        HealthMetricItem(
                            label: "RHR",
                            value: "\(rhr)",
                            unit: "bpm",
                            icon: "heart.fill",
                            color: .red
                        )
                    }
                    
                    if let hrv = viewModel.currentHRV {
                        HealthMetricItem(
                            label: "HRV",
                            value: "\(hrv)",
                            unit: "ms",
                            icon: "waveform.path.ecg",
                            color: .green
                        )
                    }
                    
                    if let spo2 = viewModel.currentSpO2 {
                        HealthMetricItem(
                            label: "SpO₂",
                            value: "\(spo2)",
                            unit: "%",
                            icon: "lungs.fill",
                            color: .cyan
                        )
                    }
                    
                    if let rr = viewModel.respiratoryRate {
                        HealthMetricItem(
                            label: "RR",
                            value: String(format: "%.1f", rr),
                            unit: "br/min",
                            icon: "wind",
                            color: .blue
                        )
                    }
                    
                    if let temp = viewModel.bodyTemperature {
                        HealthMetricItem(
                            label: "Temp",
                            value: String(format: "%.1f", temp),
                            unit: "°F",
                            icon: "thermometer.medium",
                            color: .orange
                        )
                    }
                    
                    if let glucose = viewModel.bloodGlucose {
                        HealthMetricItem(
                            label: "Glucose",
                            value: String(format: "%.0f", glucose),
                            unit: "mg/dL",
                            icon: "drop.fill",
                            color: .purple
                        )
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Stress & Energy
    
    private var stressEnergyCard: some View {
        HStack(spacing: 16) {
            // Stress
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.orange)
                        Text("Stress")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Text("\(Int(viewModel.stressLevel))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    ProgressView(value: viewModel.stressLevel / 100)
                        .tint(.orange)
                }
                .padding(16)
            }
            
            // Energy
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "battery.100")
                            .foregroundStyle(.green)
                        Text("Energy")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Text("\(Int(viewModel.energyCapacity))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    ProgressView(value: viewModel.energyCapacity / 100)
                        .tint(.green)
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        switch viewModel.activityStatus {
        case .active: return .green
        case .sick: return .orange
        case .injured: return .red
        case .onBreak: return .blue
        }
    }
    
    private func strainColor(_ value: Double) -> Color {
        switch value {
        case 0..<30: return .green
        case 30..<60: return .yellow
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private func recoveryColor(_ value: Double) -> Color {
        switch value {
        case 0..<40: return .red
        case 40..<70: return .orange
        case 70..<85: return .yellow
        default: return .green
        }
    }
}

// MARK: - Circular Progress Card

struct CircularProgressCard: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 12)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: value / 100)
                        .stroke(
                            color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: value)
                    
                    // Value
                    VStack(spacing: 2) {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                        
                        Text("\(Int(value))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 120)
                .padding(.top, 8)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
        }
    }
}

// MARK: - Sleep Card

struct SleepCard: View {
    let hours: Double
    let efficiency: Double
    
    var body: some View {
        GlassCard {
            HStack(spacing: 20) {
                // Sleep icon
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "moon.zzz.fill")
                        .font(.title)
                        .foregroundStyle(.indigo)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", hours))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("hrs")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.indigo)
                        
                        Text("\(Int(efficiency))% Efficiency")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Efficiency arc
                ZStack {
                    Circle()
                        .stroke(Color.indigo.opacity(0.2), lineWidth: 6)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: efficiency / 100)
                        .stroke(Color.indigo, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Health Metric Item

struct HealthMetricItem: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyMetrics.self, JournalEntry.self, FitnessVolume.self, configurations: config)
    let context = container.mainContext
    let viewModel = AppViewModel(isMocked: true, modelContext: context)
    
    return DashboardView(viewModel: viewModel)
}

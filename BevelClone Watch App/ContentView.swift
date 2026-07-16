//
//  ContentView.swift
//  BevelClone Watch App
//
//  Glanceable watchOS dashboard for Strain, Recovery, and Live HR
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var watchViewModel = WatchViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Live Heart Rate (Real-time)
                    liveHeartRateCard
                    
                    // The Big Two (Strain & Recovery)
                    HStack(spacing: 12) {
                        CompactMetricCard(
                            title: "Strain",
                            value: Int(watchViewModel.strain),
                            color: strainColor(watchViewModel.strain),
                            icon: "flame.fill"
                        )
                        
                        CompactMetricCard(
                            title: "Recovery",
                            value: Int(watchViewModel.recovery),
                            color: recoveryColor(watchViewModel.recovery),
                            icon: "bolt.heart.fill"
                        )
                    }
                    
                    // Activity Status
                    activityStatusRow
                    
                    // Sync Status
                    syncStatusRow
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Bevel")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            watchViewModel.activate()
        }
    }
    
    // MARK: - Live Heart Rate Card
    
    private var liveHeartRateCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                
                Text("Live HR")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                if watchViewModel.isTransmitting {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(watchViewModel.currentHeartRate)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .contentTransition(.numericText())
                
                Text("bpm")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            // Workout control button
            Button {
                watchViewModel.toggleWorkout()
            } label: {
                Label(
                    watchViewModel.isWorkoutActive ? "End Workout" : "Start Workout",
                    systemImage: watchViewModel.isWorkoutActive ? "stop.fill" : "play.fill"
                )
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(watchViewModel.isWorkoutActive ? .red : .green)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Activity Status
    
    private var activityStatusRow: some View {
        HStack {
            Image(systemName: "figure.run")
                .foregroundStyle(.orange)
            
            Text("Status:")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            
            Text(watchViewModel.activityStatus.rawValue)
                .font(.caption.bold())
                .foregroundStyle(.white)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Sync Status
    
    private var syncStatusRow: some View {
        HStack {
            Image(systemName: watchViewModel.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                .foregroundStyle(watchViewModel.isPhoneReachable ? .green : .red)
            
            Text(watchViewModel.isPhoneReachable ? "iPhone Connected" : "iPhone Disconnected")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            Spacer()
            
            Text(watchViewModel.lastSyncTime)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal)
    }
    
    // MARK: - Color Helpers
    
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

// MARK: - Compact Metric Card

struct CompactMetricCard: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text("\(value)%")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

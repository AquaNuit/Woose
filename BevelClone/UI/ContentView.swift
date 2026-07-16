//
//  ContentView.swift
//  BevelClone
//
//  Main tab navigation container
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AppViewModel?
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                TabView(selection: $selectedTab) {
                    DashboardView(viewModel: viewModel, selectedTab: $selectedTab)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    JournalView(viewModel: viewModel)
                        .tabItem {
                            Label("Journal", systemImage: "book.fill")
                        }
                        .tag(1)
                    
                    FitnessView(viewModel: viewModel)
                        .tabItem {
                            Label("Fitness", systemImage: "figure.strengthtraining.traditional")
                        }
                        .tag(2)
                    
                    BiologyView(viewModel: viewModel)
                        .tabItem {
                            Label("Biology", systemImage: "heart.text.square.fill")
                        }
                        .tag(3)
                }
                .preferredColorScheme(.dark)
            } else {
                ProgressView("Loading Health Data...")
                    .preferredColorScheme(.dark)
            }
        }
        .onAppear {
            initializeViewModel()
        }
    }
    
    private func initializeViewModel() {
        // Check if running in Swift Playgrounds or Xcode Previews
        let isMockedEnvironment = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        // For production: Change to `isMocked: false` to use real HealthKit data
        viewModel = AppViewModel(isMocked: isMockedEnvironment, modelContext: modelContext)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [DailyMetrics.self, JournalEntry.self, FitnessVolume.self], inMemory: true)
}

//
//  BevelCloneApp.swift
//  BevelClone
//
//  Main app entry point with SwiftData configuration
//

import SwiftUI
import SwiftData

@main
struct BevelCloneApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            DailyMetrics.self,
            JournalEntry.self,
            FitnessVolume.self
        ])
    }
}

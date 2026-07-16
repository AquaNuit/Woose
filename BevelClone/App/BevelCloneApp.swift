//
//  BevelCloneApp.swift
//  BevelClone
//
//  Main app entry point with SwiftData configuration and background tasks
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct BevelCloneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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

// MARK: - App Delegate for Background Tasks

class AppDelegate: NSObject, UIApplicationDelegate {
    
    // Background task identifier
    static let backgroundTaskIdentifier = "com.bevelclone.healthsync"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Register background processing task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppDelegate.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundHealthSync(task: task as! BGProcessingTask)
        }
        
        print("✅ Background task registered: \(AppDelegate.backgroundTaskIdentifier)")
        
        // Schedule initial background sync
        scheduleBackgroundHealthSync()
        
        return true
    }
    
    // MARK: - Background Task Scheduling
    
    func scheduleBackgroundHealthSync() {
        let request = BGProcessingTaskRequest(identifier: AppDelegate.backgroundTaskIdentifier)
        
        // Require external power (charging) for heavy calculations
        request.requiresExternalPower = true
        
        // Require network connectivity (optional, for future cloud sync)
        request.requiresNetworkConnectivity = false
        
        // Earliest begin date (15 minutes from now)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background sync scheduled")
        } catch {
            print("❌ Failed to schedule background sync: \(error)")
        }
    }
    
    // MARK: - Background Task Handler
    
    private func handleBackgroundHealthSync(task: BGProcessingTask) {
        print("🔄 Background sync started")
        
        // Schedule next sync
        scheduleBackgroundHealthSync()
        
        // Create background task with expiration handler
        task.expirationHandler = {
            print("⚠️ Background sync expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform heavy SwiftData calculations
        Task {
            do {
                // In production: Recalculate 30/90-day rolling averages
                // Query HealthKit for new data since last sync
                // Update DailyMetrics in SwiftData
                
                try await Task.sleep(nanoseconds: 5_000_000_000) // Simulate 5s work
                
                print("✅ Background sync completed")
                task.setTaskCompleted(success: true)
                
            } catch {
                print("❌ Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
}

// MARK: - Background Task Helper (for manual testing)

extension AppDelegate {
    
    /// Simulate background task (for Xcode debugging only)
    /// Usage: e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.bevelclone.healthsync"]
    static func simulateBackgroundTask() {
        #if DEBUG
        print("🧪 Simulating background task...")
        #endif
    }
}

//
//  WatchViewModel.swift
//  BevelClone Watch App
//
//  ViewModel managing Watch state and iPhone sync
//

import Foundation
import SwiftUI
import WatchConnectivity
import HealthKit

@MainActor
class WatchViewModel: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    @Published var currentHeartRate: Int = 0
    @Published var strain: Double = 0
    @Published var recovery: Double = 0
    @Published var activityStatus: ActivityStatus = .active
    
    @Published var isWorkoutActive: Bool = false
    @Published var isTransmitting: Bool = false
    @Published var isPhoneReachable: Bool = false
    @Published var lastSyncTime: String = "Never"
    
    // MARK: - Properties
    
    private var session: WCSession?
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    private var workoutSession: HKWorkoutSession?
    
    private var heartRateUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Activation
    
    func activate() {
        // Activate WCSession
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        
        // Request HealthKit authorization
        Task {
            await requestHealthKitAuthorization()
        }
        
        print("🔄 Watch: ViewModel activated")
    }
    
    // MARK: - HealthKit Authorization
    
    private func requestHealthKitAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ Watch: HealthKit not available")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            print("✅ Watch: HealthKit authorized")
        } catch {
            print("❌ Watch: HealthKit authorization failed: \(error)")
        }
    }
    
    // MARK: - Workout Control
    
    func toggleWorkout() {
        if isWorkoutActive {
            endWorkout()
        } else {
            startWorkout()
        }
    }
    
    private func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            session.delegate = self
            
            workoutSession = session
            
            healthStore.start(session)
            
            // Start heart rate monitoring
            startHeartRateMonitoring()
            
            isWorkoutActive = true
            isTransmitting = true
            
            print("✅ Watch: Workout started")
        } catch {
            print("❌ Watch: Failed to start workout: \(error)")
        }
    }
    
    private func endWorkout() {
        guard let session = workoutSession else { return }
        
        healthStore.end(session)
        
        // Stop heart rate monitoring
        stopHeartRateMonitoring()
        
        workoutSession = nil
        isWorkoutActive = false
        isTransmitting = false
        
        print("✅ Watch: Workout ended")
    }
    
    // MARK: - Heart Rate Monitoring
    
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.processHeartRateSamples(samples)
            }
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            Task { @MainActor in
                self?.processHeartRateSamples(samples)
            }
        }
        
        healthStore.execute(query)
        heartRateQuery = query
        
        print("✅ Watch: Heart rate monitoring started")
    }
    
    private func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        
        print("✅ Watch: Heart rate monitoring stopped")
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample],
              let mostRecent = heartRateSamples.last else {
            return
        }
        
        let bpm = mostRecent.quantity.doubleValue(for: HKUnit(from: "count/min"))
        
        Task { @MainActor in
            currentHeartRate = Int(bpm)
            
            // Send to iPhone if workout is active
            if isWorkoutActive {
                sendHeartRateToiPhone(bpm: bpm)
            }
        }
    }
    
    // MARK: - iPhone Communication
    
    private func sendHeartRateToiPhone(bpm: Double) {
        guard let session = session, session.isReachable else {
            print("⚠️ Watch: iPhone not reachable")
            return
        }
        
        let message: [String: Any] = [
            "type": "realtimeHeartRate",
            "payload": [
                "bpm": bpm,
                "timestamp": Date().timeIntervalSince1970
            ]
        ]
        
        session.sendMessage(message, replyHandler: { response in
            print("✅ Watch: HR sent (\(Int(bpm)) bpm) - iPhone acknowledged")
        }, errorHandler: { error in
            print("❌ Watch: Failed to send HR: \(error.localizedDescription)")
        })
    }
    
    private func updateLastSyncTime() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        lastSyncTime = formatter.string(from: Date())
    }
}

// MARK: - WCSessionDelegate

extension WatchViewModel: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ Watch: Session activation failed: \(error)")
                return
            }
            
            isPhoneReachable = session.isReachable
            
            switch activationState {
            case .activated:
                print("✅ Watch: WCSession activated")
            case .inactive:
                print("⚠️ Watch: WCSession inactive")
            case .notActivated:
                print("⚠️ Watch: WCSession not activated")
            @unknown default:
                print("⚠️ Watch: Unknown activation state")
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable
            print("🔄 Watch: iPhone reachability: \(session.isReachable)")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            handleReceivedContext(applicationContext)
        }
    }
    
    @MainActor
    private func handleReceivedContext(_ context: [String: Any]) {
        guard let type = context["type"] as? String,
              let payload = context["payload"] as? [String: Any] else {
            return
        }
        
        switch type {
        case "dailyContext":
            if let strain = payload["strain"] as? Double {
                self.strain = strain
            }
            if let recovery = payload["recovery"] as? Double {
                self.recovery = recovery
            }
            if let statusRaw = payload["activityStatus"] as? String,
               let status = ActivityStatus(rawValue: statusRaw) {
                self.activityStatus = status
            }
            
            updateLastSyncTime()
            print("📥 Watch: Received daily context from iPhone")
            
        default:
            print("⚠️ Watch: Unknown context type: \(type)")
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchViewModel: HKWorkoutSessionDelegate {
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            switch toState {
            case .running:
                print("✅ Watch: Workout session running")
            case .ended:
                print("✅ Watch: Workout session ended")
            case .paused:
                print("⏸️ Watch: Workout session paused")
            default:
                break
            }
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Watch: Workout session failed: \(error)")
            endWorkout()
        }
    }
}

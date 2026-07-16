//
//  WatchSyncEngine.swift
//  BevelClone
//
//  WatchConnectivity bidirectional sync engine
//  Phase 1: Backend Foundation
//

import Foundation
import WatchConnectivity

// MARK: - Watch Sync Errors

enum WatchSyncError: LocalizedError {
    case notSupported
    case sessionNotActivated
    case watchNotPaired
    case watchNotReachable
    case transferFailed(String)
    case serializationFailed
    
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "WatchConnectivity is not supported on this device"
        case .sessionNotActivated:
            return "WCSession has not been activated"
        case .watchNotPaired:
            return "Apple Watch is not paired"
        case .watchNotReachable:
            return "Apple Watch is not currently reachable"
        case .transferFailed(let reason):
            return "Watch sync failed: \(reason)"
        case .serializationFailed:
            return "Failed to serialize data for Watch transfer"
        }
    }
}

// MARK: - Watch Message Keys

private enum MessageKey {
    static let type = "type"
    static let payload = "payload"
    static let timestamp = "timestamp"
    
    // Message types
    static let realtimeHeartRate = "realtimeHeartRate"
    static let dailyContext = "dailyContext"
    static let workoutSession = "workoutSession"
}

// MARK: - WatchSyncEngine

/// Singleton manager for iPhone ↔ Apple Watch communication
@MainActor
final class WatchSyncEngine: NSObject {
    
    // MARK: - Singleton
    
    static let shared = WatchSyncEngine()
    
    private var session: WCSession?
    
    // Callback for received data
    var onDataReceived: ((String, [String: Any]) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Activation
    
    /// Activate WatchConnectivity session
    func activate() {
        guard WCSession.isSupported() else {
            print("⚠️ WatchConnectivity not supported on this device")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("🔄 WatchSyncEngine: Activating session...")
    }
    
    // MARK: - Session State
    
    var isSupported: Bool {
        WCSession.isSupported()
    }
    
    var isActivated: Bool {
        session?.activationState == .activated
    }
    
    var isPaired: Bool {
        #if os(iOS)
        return session?.isPaired ?? false
        #else
        return false
        #endif
    }
    
    var isWatchAppInstalled: Bool {
        #if os(iOS)
        return session?.isWatchAppInstalled ?? false
        #else
        return false
        #endif
    }
    
    var isReachable: Bool {
        session?.isReachable ?? false
    }
    
    // MARK: - Real-time Messaging (sendMessage)
    
    /// Send real-time heart rate during active workout (requires Watch reachability)
    /// Uses sendMessage for immediate delivery - falls back to updateApplicationContext if Watch unreachable
    func sendRealtimeHeartRate(_ bpm: Double) throws {
        guard isActivated else {
            throw WatchSyncError.sessionNotActivated
        }
        
        let message: [String: Any] = [
            MessageKey.type: MessageKey.realtimeHeartRate,
            MessageKey.payload: [
                "bpm": bpm,
                "timestamp": Date().timeIntervalSince1970
            ]
        ]
        
        if isReachable {
            // Real-time: Use sendMessage for immediate delivery
            session?.sendMessage(message, replyHandler: { response in
                print("✅ Real-time HR sent: \(bpm) bpm - Watch acknowledged")
            }, errorHandler: { error in
                print("❌ Real-time HR send failed: \(error.localizedDescription)")
                // Fallback to application context
                self.fallbackToContext(message: message)
            })
        } else {
            // Watch not reachable: Use application context as fallback
            print("⚠️ Watch not reachable, using background sync for HR data")
            fallbackToContext(message: message)
        }
    }
    
    /// Send workout session data in real-time
    func sendWorkoutSessionData(_ workoutData: [String: Any]) throws {
        guard isActivated else {
            throw WatchSyncError.sessionNotActivated
        }
        
        let message: [String: Any] = [
            MessageKey.type: MessageKey.workoutSession,
            MessageKey.payload: workoutData,
            MessageKey.timestamp: Date().timeIntervalSince1970
        ]
        
        if isReachable {
            session?.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("❌ Workout session send failed: \(error.localizedDescription)")
            })
        } else {
            fallbackToContext(message: message)
        }
    }
    
    // MARK: - Background Context Sync (updateApplicationContext)
    
    /// Update daily metrics context (persistent background sync)
    /// Uses updateApplicationContext - system delivers when devices reconnect
    func updateDailyContext(_ metrics: DailyMetrics) throws {
        guard isActivated else {
            throw WatchSyncError.sessionNotActivated
        }
        
        // Serialize DailyMetrics to dictionary
        guard let contextData = try? serializeMetrics(metrics) else {
            throw WatchSyncError.serializationFailed
        }
        
        let context: [String: Any] = [
            MessageKey.type: MessageKey.dailyContext,
            MessageKey.payload: contextData,
            MessageKey.timestamp: Date().timeIntervalSince1970
        ]
        
        do {
            try session?.updateApplicationContext(context)
            print("✅ Daily context updated: \(metrics.date.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            throw WatchSyncError.transferFailed(error.localizedDescription)
        }
    }
    
    /// Update multiple days of data in bulk (for initial sync or catch-up)
    func updateBulkContext(metrics: [DailyMetrics]) throws {
        guard isActivated else {
            throw WatchSyncError.sessionNotActivated
        }
        
        let serializedMetrics = try metrics.compactMap { try? serializeMetrics($0) }
        
        let context: [String: Any] = [
            MessageKey.type: "bulkSync",
            MessageKey.payload: serializedMetrics,
            MessageKey.timestamp: Date().timeIntervalSince1970
        ]
        
        do {
            try session?.updateApplicationContext(context)
            print("✅ Bulk context updated: \(metrics.count) days")
        } catch {
            throw WatchSyncError.transferFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Fallback Strategy
    
    private func fallbackToContext(message: [String: Any]) {
        do {
            try session?.updateApplicationContext(message)
            print("🔄 Fell back to application context for message delivery")
        } catch {
            print("❌ Fallback failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Serialization
    
    private func serializeMetrics(_ metrics: DailyMetrics) throws -> [String: Any] {
        [
            "date": metrics.date.timeIntervalSince1970,
            "strain": metrics.activityData.strain,
            "recovery": metrics.activityData.recovery,
            "sleepHours": metrics.sleepData.totalDuration ?? 0,
            "sleepEfficiency": metrics.sleepData.sleepEfficiency ?? 0,
            "rhr": metrics.heartData.restingHeartRate ?? 0,
            "hrv": metrics.heartData.heartRateVariability ?? 0,
            "respiratoryRate": metrics.heartData.respiratoryRate ?? 0,
            "spo2": metrics.vitalsData.oxygenSaturation ?? 0,
            "bodyTemp": metrics.vitalsData.bodyTemperature ?? 0,
            "steps": metrics.activityData.steps ?? 0,
            "activeEnergy": metrics.activityData.activeEnergyBurned ?? 0,
            "activityStatus": metrics.activityStatus.rawValue
        ]
    }
    
    private func deserializeMetrics(_ data: [String: Any]) -> DailyMetrics? {
        guard let timestamp = data["date"] as? TimeInterval else { return nil }
        
        let date = Date(timeIntervalSince1970: timestamp)
        
        let heartData = HeartMetrics(
            restingHeartRate: data["rhr"] as? Int,
            heartRateVariability: data["hrv"] as? Int,
            respiratoryRate: data["respiratoryRate"] as? Double
        )
        
        let sleepData = SleepMetrics(
            totalDuration: data["sleepHours"] as? Double,
            sleepEfficiency: data["sleepEfficiency"] as? Double
        )
        
        let activityData = ActivityMetrics(
            strain: data["strain"] as? Double ?? 0,
            recovery: data["recovery"] as? Double ?? 0,
            energyCapacity: data["energyCapacity"] as? Double ?? 0,
            activeEnergyBurned: data["activeEnergy"] as? Double,
            steps: data["steps"] as? Int
        )
        
        let vitalsData = VitalsMetrics(
            oxygenSaturation: data["spo2"] as? Int,
            bodyTemperature: data["bodyTemp"] as? Double
        )
        
        let statusRaw = data["activityStatus"] as? String ?? "Active"
        let status = ActivityStatus(rawValue: statusRaw) ?? .active
        
        return DailyMetrics(
            date: date,
            heartData: heartData,
            sleepData: sleepData,
            activityData: activityData,
            vitalsData: vitalsData,
            activityStatus: status
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncEngine: WCSessionDelegate {
    
    // MARK: - Activation
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ WCSession activation failed: \(error.localizedDescription)")
                return
            }
            
            switch activationState {
            case .activated:
                print("✅ WCSession activated successfully")
            case .inactive:
                print("⚠️ WCSession is inactive")
            case .notActivated:
                print("⚠️ WCSession is not activated")
            @unknown default:
                print("⚠️ Unknown WCSession activation state")
            }
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            print("🔄 WCSession became inactive")
        }
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            print("🔄 WCSession deactivated - reactivating...")
            session.activate()
        }
    }
    #endif
    
    // MARK: - Reachability
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            let status = session.isReachable ? "✅ reachable" : "❌ not reachable"
            print("🔄 Watch reachability changed: \(status)")
        }
    }
    
    // MARK: - Receive Messages (Real-time)
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            handleReceivedMessage(message)
            
            // Send acknowledgment
            replyHandler(["status": "received", "timestamp": Date().timeIntervalSince1970])
        }
    }
    
    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let messageType = message[MessageKey.type] as? String,
              let payload = message[MessageKey.payload] as? [String: Any] else {
            print("⚠️ Received malformed message")
            return
        }
        
        print("📥 Received message: \(messageType)")
        
        // Notify observer (typically AppViewModel)
        onDataReceived?(messageType, payload)
        
        // Handle specific message types
        switch messageType {
        case MessageKey.realtimeHeartRate:
            if let bpm = payload["bpm"] as? Double {
                print("💓 Real-time HR from Watch: \(Int(bpm)) bpm")
            }
            
        case MessageKey.workoutSession:
            print("🏋️ Workout session data received from Watch")
            
        default:
            print("⚠️ Unknown message type: \(messageType)")
        }
    }
    
    // MARK: - Receive Application Context (Background Sync)
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            handleReceivedContext(applicationContext)
        }
    }
    
    @MainActor
    private func handleReceivedContext(_ context: [String: Any]) {
        guard let messageType = context[MessageKey.type] as? String else {
            print("⚠️ Received malformed application context")
            return
        }
        
        print("📥 Received application context: \(messageType)")
        
        switch messageType {
        case MessageKey.dailyContext:
            if let payload = context[MessageKey.payload] as? [String: Any],
               let metrics = deserializeMetrics(payload) {
                print("📊 Daily metrics received: \(metrics.date.formatted(date: .abbreviated, time: .omitted))")
                
                // Notify observer
                onDataReceived?(messageType, payload)
            }
            
        case "bulkSync":
            if let payloads = context[MessageKey.payload] as? [[String: Any]] {
                print("📊 Bulk sync received: \(payloads.count) days")
            }
            
        default:
            print("⚠️ Unknown context type: \(messageType)")
        }
    }
    
    // MARK: - User Info Transfer (Large Data)
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            print("📦 Received user info transfer")
        }
    }
    
    nonisolated func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ User info transfer failed: \(error.localizedDescription)")
            } else {
                print("✅ User info transfer completed")
            }
        }
    }
}

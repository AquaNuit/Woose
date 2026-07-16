//
//  HealthKitManager.swift
//  BevelClone
//
//  HealthKit authorization and data ingestion manager
//  Phase 1: Backend Foundation
//
//  IMPORTANT: Add this to Info.plist:
//  <key>NSHealthShareUsageDescription</key>
//  <string>Bevel Clone needs access to your health data to calculate Strain, Recovery, Sleep quality, and Biological Age metrics. Your data stays private on your device.</string>
//

import Foundation
import HealthKit

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case noData
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .noData:
            return "No health data available for the requested period"
        case .queryFailed(let reason):
            return "HealthKit query failed: \(reason)"
        }
    }
}

// MARK: - HealthKitManager

/// Singleton manager for HealthKit authorization and data queries
@MainActor
final class HealthKitManager {
    
    // MARK: - Singleton
    
    static let shared = HealthKitManager()
    
    private let healthStore: HKHealthStore
    
    private init() {
        self.healthStore = HKHealthStore()
    }
    
    // MARK: - Availability
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization Types
    
    /// Complete array of HealthKit types to read
    private var typesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Quantity Types
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .respiratoryRate,
            .oxygenSaturation,
            .bodyTemperature,
            .bloodGlucose,
            .activeEnergyBurned,
            .vo2Max,
            .bodyFatPercentage,
            .leanBodyMass,
            .bodyMass,
            .environmentalAudioExposure,
            .appleExerciseTime,
            .distanceWalkingRunning
        ]
        
        for identifier in quantityTypes {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }
        
        // Category Types
        if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        
        if let mindfulSession = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulSession)
        }
        
        // Workout Type
        types.insert(HKObjectType.workoutType())
        
        // Correlation Types (Blood Pressure)
        if let bloodPressure = HKObjectType.correlationType(forIdentifier: .bloodPressure) {
            types.insert(bloodPressure)
        }
        
        return types
    }
    
    /// Types to share (write) - empty for Phase 1 (read-only app)
    private var typesToShare: Set<HKSampleType> {
        Set<HKSampleType>()
    }
    
    // MARK: - Authorization
    
    /// Request HealthKit authorization for all required types
    func requestAuthorization() async throws -> Bool {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            
            // Check if at least some critical types were authorized
            let criticalTypes = [
                HKQuantityType.quantityType(forIdentifier: .heartRate),
                HKQuantityType.quantityType(forIdentifier: .stepCount),
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            ].compactMap { $0 }
            
            let hasAuthorization = criticalTypes.contains { type in
                let status = healthStore.authorizationStatus(for: type)
                return status == .sharingAuthorized
            }
            
            return hasAuthorization
        } catch {
            throw HealthKitError.queryFailed(error.localizedDescription)
        }
    }
    
    /// Check authorization status for a specific type
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }
    
    // MARK: - Daily Metrics Queries
    
    /// Fetch comprehensive daily metrics for a specific date
    func fetchDailyMetrics(for date: Date) async throws -> DailyMetrics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.queryFailed("Invalid date range")
        }
        
        // Query all metrics in parallel
        async let heartData = fetchHeartMetrics(from: startOfDay, to: endOfDay)
        async let sleepData = fetchSleepMetrics(for: date)
        async let activityData = fetchActivityMetrics(from: startOfDay, to: endOfDay)
        async let vitalsData = fetchVitalsMetrics(from: startOfDay, to: endOfDay)
        
        let heart = try await heartData
        let sleep = try await sleepData
        let activity = try await activityData
        let vitals = try await vitalsData
        
        return DailyMetrics(
            date: startOfDay,
            heartData: heart,
            sleepData: sleep,
            activityData: activity,
            vitalsData: vitals,
            activityStatus: .active
        )
    }
    
    // MARK: - Heart Metrics
    
    /// Fetch heart-related metrics (RHR, HRV, Respiratory Rate)
    private func fetchHeartMetrics(from startDate: Date, to endDate: Date) async throws -> HeartMetrics {
        async let rhr = fetchMostRecentSample(
            typeIdentifier: .restingHeartRate,
            from: startDate,
            to: endDate,
            unit: .count().unitDivided(by: .minute())
        )
        
        async let hrv = fetchMostRecentSample(
            typeIdentifier: .heartRateVariabilitySDNN,
            from: startDate,
            to: endDate,
            unit: .secondUnit(with: .milli)
        )
        
        async let rr = fetchMostRecentSample(
            typeIdentifier: .respiratoryRate,
            from: startDate,
            to: endDate,
            unit: .count().unitDivided(by: .minute())
        )
        
        let rhrValue = try? await rhr
        let hrvValue = try? await hrv
        let rrValue = try? await rr
        
        return HeartMetrics(
            restingHeartRate: rhrValue.map { Int($0) },
            heartRateVariability: hrvValue.map { Int($0) },
            respiratoryRate: rrValue
        )
    }
    
    // MARK: - Sleep Metrics
    
    /// Fetch sleep analysis for a specific date
    func fetchSleepAnalysis(for date: Date) async throws -> SleepMetrics {
        try await fetchSleepMetrics(for: date)
    }
    
    private func fetchSleepMetrics(for date: Date) async throws -> SleepMetrics {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return SleepMetrics()
        }
        
        let calendar = Calendar.current
        // Sleep for a given day typically spans the previous night
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return SleepMetrics()
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard error == nil, let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: SleepMetrics())
                    return
                }
                
                var totalSleepMinutes: Double = 0
                var deepSleepMinutes = 0
                var remSleepMinutes = 0
                var awakeMinutes = 0
                
                for sample in sleepSamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                    
                    if #available(iOS 16.0, *) {
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                             HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            deepSleepMinutes += Int(duration)
                            totalSleepMinutes += duration
                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            remSleepMinutes += Int(duration)
                            totalSleepMinutes += duration
                        case HKCategoryValueSleepAnalysis.awake.rawValue:
                            awakeMinutes += Int(duration)
                        default:
                            totalSleepMinutes += duration
                        }
                    } else {
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            totalSleepMinutes += duration
                        } else if sample.value == HKCategoryValueSleepAnalysis.awake.rawValue {
                            awakeMinutes += Int(duration)
                        }
                    }
                }
                
                let totalHours = totalSleepMinutes / 60.0
                let efficiency = totalSleepMinutes > 0 ? (totalSleepMinutes / (totalSleepMinutes + Double(awakeMinutes))) * 100 : 0
                
                let metrics = SleepMetrics(
                    totalDuration: totalHours,
                    sleepEfficiency: efficiency,
                    deepSleepMinutes: deepSleepMinutes,
                    remSleepMinutes: remSleepMinutes,
                    awakeMinutes: awakeMinutes
                )
                
                continuation.resume(returning: metrics)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Activity Metrics
    
    private func fetchActivityMetrics(from startDate: Date, to endDate: Date) async throws -> ActivityMetrics {
        async let steps = fetchStatisticsSum(
            typeIdentifier: .stepCount,
            from: startDate,
            to: endDate,
            unit: .count()
        )
        
        async let activeEnergy = fetchStatisticsSum(
            typeIdentifier: .activeEnergyBurned,
            from: startDate,
            to: endDate,
            unit: .kilocalorie()
        )
        
        let stepsValue = (try? await steps) ?? 0
        let activeEnergyValue = (try? await activeEnergy) ?? 0
        
        // Calculate Strain based on active energy and steps (simplified algorithm)
        let strain = calculateStrain(activeEnergy: activeEnergyValue, steps: Int(stepsValue))
        
        // Calculate Recovery (placeholder - would need HRV trends in production)
        let recovery = calculateRecovery()
        
        return ActivityMetrics(
            strain: strain,
            recovery: recovery,
            energyCapacity: (recovery * 0.7) + 30.0,
            activeEnergyBurned: activeEnergyValue,
            steps: Int(stepsValue)
        )
    }
    
    // MARK: - Vitals Metrics
    
    private func fetchVitalsMetrics(from startDate: Date, to endDate: Date) async throws -> VitalsMetrics {
        async let spo2 = fetchMostRecentSample(
            typeIdentifier: .oxygenSaturation,
            from: startDate,
            to: endDate,
            unit: .percent()
        )
        
        async let temp = fetchMostRecentSample(
            typeIdentifier: .bodyTemperature,
            from: startDate,
            to: endDate,
            unit: .degreeFahrenheit()
        )
        
        async let glucose = fetchMostRecentSample(
            typeIdentifier: .bloodGlucose,
            from: startDate,
            to: endDate,
            unit: HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        )
        
        let spo2Value = try? await spo2
        let tempValue = try? await temp
        let glucoseValue = try? await glucose
        
        return VitalsMetrics(
            oxygenSaturation: spo2Value.map { Int($0 * 100) },
            bodyTemperature: tempValue,
            bloodGlucose: glucoseValue
        )
    }
    
    // MARK: - Real-time Queries
    
    /// Fetch most recent heart rate sample (for Health Monitor real-time display)
    func fetchRealtimeHeartRate() async throws -> Double? {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300)
        
        return try await fetchMostRecentSample(
            typeIdentifier: .heartRate,
            from: fiveMinutesAgo,
            to: now,
            unit: .count().unitDivided(by: .minute())
        )
    }
    
    // MARK: - Workouts
    
    /// Fetch all workouts for a specific date
    func fetchWorkouts(for date: Date) async throws -> [HKWorkout] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard error == nil, let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: workouts)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Journal Triggers
    
    /// Check which automatic journal habits should be triggered for a date
    func fetchJournalTriggers(for date: Date) async throws -> Set<JournalHabit> {
        var triggers = Set<JournalHabit>()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return triggers
        }
        
        // Check 10k+ steps
        if let steps = try? await fetchStatisticsSum(typeIdentifier: .stepCount, from: startOfDay, to: endOfDay, unit: .count()),
           steps >= 10000 {
            triggers.insert(.steps10k)
        }
        
        // Check workouts for cardio/strength duration
        let workouts = try await fetchWorkouts(for: date)
        
        for workout in workouts {
            let duration = workout.duration / 60.0  // minutes
            
            if duration >= 20 {
                switch workout.workoutActivityType {
                case .running, .cycling, .swimming, .rowing, .hiking, .walking:
                    triggers.insert(.cardio20min)
                case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
                    triggers.insert(.strength20min)
                default:
                    break
                }
            }
        }
        
        // Check environmental audio (sleeping noise)
        if let audioExposure = try? await fetchStatisticsAverage(
            typeIdentifier: .environmentalAudioExposure,
            from: startOfDay,
            to: endOfDay,
            unit: .decibelAWeightedSoundPressureLevel()
        ), audioExposure >= 50 {
            triggers.insert(.sleepingNoise50dB)
        }
        
        // Check daylight exposure (UV exposure as proxy)
        if let exerciseTime = try? await fetchStatisticsSum(
            typeIdentifier: .appleExerciseTime,
            from: startOfDay,
            to: endOfDay,
            unit: .minute()
        ), exerciseTime >= 20 {
            triggers.insert(.daylight20min)
        }
        
        return triggers
    }
    
    // MARK: - Observer Queries
    
    /// Start observing health changes for real-time updates
    func startObservingHealthChanges(handler: @escaping @MainActor (HKSampleType) -> Void) {
        let typesToObserve: [HKSampleType] = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        
        for sampleType in typesToObserve {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, error in
                guard error == nil else {
                    completionHandler()
                    return
                }
                
                Task { @MainActor in
                    handler(sampleType)
                }
                
                completionHandler()
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchMostRecentSample(typeIdentifier: HKQuantityTypeIdentifier, from startDate: Date, to endDate: Date, unit: HKUnit) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    private func fetchStatisticsSum(typeIdentifier: HKQuantityTypeIdentifier, from startDate: Date, to endDate: Date, unit: HKUnit) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                guard error == nil, let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let value = sum.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    private func fetchStatisticsAverage(typeIdentifier: HKQuantityTypeIdentifier, from startDate: Date, to endDate: Date, unit: HKUnit) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, error in
                guard error == nil, let average = statistics?.averageQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let value = average.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Calculation Algorithms
    
    private func calculateStrain(activeEnergy: Double, steps: Int) -> Double {
        // Simplified strain calculation (0-100 scale)
        // Production would use heart rate zones, workout intensity, and training load
        let energyContribution = min(activeEnergy / 10.0, 50.0)
        let stepsContribution = min(Double(steps) / 400.0, 50.0)
        return energyContribution + stepsContribution
    }
    
    private func calculateRecovery() -> Double {
        // Placeholder recovery calculation
        // Production would use HRV trends, sleep quality, and resting heart rate
        return 75.0
    }
}

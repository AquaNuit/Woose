//
//  AppViewModel.swift
//  BevelClone
//
//  Central ViewModel with strict decoupling for mock/real data modes
//  Phase 1: Backend Foundation
//

import Foundation
import SwiftData
import Observation

// MARK: - Identifiable Chart Point (for Charts framework)

/// Chart-ready data point with Identifiable conformance
struct IdentifiableChartPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let value: Double
    let label: String
    
    init(id: UUID = UUID(), date: Date, value: Double, label: String) {
        self.id = id
        self.date = date
        self.value = value
        self.label = label
    }
}

// MARK: - AppViewModel

/// Central ViewModel bridging UI to backend with mock/real data toggle
@Observable
@MainActor
final class AppViewModel {
    
    // MARK: - Core Properties
    
    let isMocked: Bool
    private let modelContext: ModelContext
    
    // References to backend managers (only used if !isMocked)
    // Note: These would be initialized in setupRealDataPipeline()
    // private var healthKitManager: HealthKitManager?
    // private var watchSyncEngine: WatchSyncEngine?
    
    // MARK: - Published State (Dashboard)
    
    var strain: Double = 0.0
    var recovery: Double = 0.0
    var sleepHours: Double = 0.0
    var sleepEfficiency: Double = 0.0
    var activityStatus: ActivityStatus = .active
    
    // MARK: - Published State (Health Monitor)
    
    var currentRHR: Int?
    var currentHRV: Int?
    var currentSpO2: Int?
    var respiratoryRate: Double?
    var bodyTemperature: Double?
    var bloodGlucose: Double?
    
    // MARK: - Published State (Journal)
    
    var journalEntries: [JournalEntry] = []
    
    // MARK: - Published State (Fitness)
    
    var fitnessVolumes: [FitnessVolume] = []
    
    // MARK: - Published State (Biology)
    
    var biologicalAge: Double = 0.0
    var chronologicalAge: Double = 30.0  // Default, should be set from user profile
    var weight: Double?
    var bodyFatPercentage: Double?
    var leanBodyMass: Double?
    var vo2Max: Double?
    
    // MARK: - Published State (Authorization)
    
    var healthKitAuthorized: Bool = false
    var authorizationError: String?
    
    // MARK: - Computed Properties
    
    var needsHealthKitPermission: Bool {
        !isMocked && !healthKitAuthorized
    }
    
    var stressLevel: Double {
        // Inverse relationship: high recovery = low stress
        max(0, 100 - recovery)
    }
    
    var energyCapacity: Double {
        // Blend of recovery and sleep quality
        (recovery * 0.7) + (sleepEfficiency * 0.3)
    }
    
    // MARK: - Initialization
    
    init(isMocked: Bool, modelContext: ModelContext) {
        self.isMocked = isMocked
        self.modelContext = modelContext
        
        if isMocked {
            loadMockData()
        } else {
            Task { await setupRealDataPipeline() }
        }
    }
    
    // MARK: - Mock Data Generation
    
    /// Generate complete 90-day narrative dataset for UI development
    private func loadMockData() {
        print("📱 AppViewModel: Loading mock data for Swift Playgrounds compatibility")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Seeded random generator for reproducibility
        var seededRandom = SeededRandomGenerator(seed: 42)
        
        // Generate 90 days of journal entries and daily metrics
        for dayOffset in -89...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Determine narrative phase
            let phase: NarrativePhase
            if dayOffset >= -14 && dayOffset <= 0 {
                phase = .injured  // Days 1-14: Injured state
            } else if dayOffset >= -30 && dayOffset < -14 {
                phase = .recovery  // Days 15-30: Recovery transition
            } else {
                phase = .active    // Days 31-90: Consistent training
            }
            
            // Generate daily metrics
            let dailyMetrics = generateDailyMetrics(for: date, phase: phase, random: &seededRandom)
            modelContext.insert(dailyMetrics)
            
            // Generate journal entry
            let journalEntry = generateJournalEntry(for: date, phase: phase, random: &seededRandom)
            modelContext.insert(journalEntry)
        }
        
        // Generate 30 days of fitness volume
        for dayOffset in -29...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            let phase: NarrativePhase
            if dayOffset >= -14 && dayOffset <= 0 {
                phase = .injured
            } else if dayOffset >= -30 && dayOffset < -14 {
                phase = .recovery
            } else {
                phase = .active
            }
            
            let fitnessVolume = generateFitnessVolume(for: date, phase: phase, random: &seededRandom)
            modelContext.insert(fitnessVolume)
        }
        
        // Save all generated data
        try? modelContext.save()
        
        // Load into memory for UI binding
        refreshFromCache()
        
        // Set current dashboard values from today's data
        if let todayMetrics = journalEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
            // Dashboard values are already set by refreshFromCache
        }
        
        print("✅ Mock data loaded: 90 journal entries, 30 fitness records")
    }
    
    /// Generate realistic daily metrics for a specific narrative phase
    private func generateDailyMetrics(for date: Date, phase: NarrativePhase, random: inout SeededRandomGenerator) -> DailyMetrics {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let isWorkoutDay = (dayOfWeek == 2 || dayOfWeek == 4 || dayOfWeek == 6)  // Mon, Wed, Fri
        
        // Base values with phase-specific modulation
        var strainValue: Double
        var recoveryValue: Double
        var sleepDuration: Double
        var sleepEff: Double
        let status: ActivityStatus
        
        switch phase {
        case .injured:
            status = .injured
            strainValue = random.double(in: 20...35)
            recoveryValue = random.double(in: 40...55)
            sleepDuration = random.double(in: 5.5...7.0)
            sleepEff = random.double(in: 70...82)
            
        case .recovery:
            status = .active
            strainValue = isWorkoutDay ? random.double(in: 35...50) : random.double(in: 15...30)
            recoveryValue = random.double(in: 55...70)
            sleepDuration = random.double(in: 6.5...7.8)
            sleepEff = random.double(in: 78...88)
            
        case .active:
            status = .active
            strainValue = isWorkoutDay ? random.double(in: 65...80) : random.double(in: 20...30)
            recoveryValue = random.double(in: 75...85)
            sleepDuration = random.double(in: 7.0...8.5)
            sleepEff = random.double(in: 85...95)
        }
        
        // Correlate poor sleep with lower recovery
        if sleepDuration < 6.5 {
            recoveryValue *= 0.85
            sleepEff *= 0.90
        }
        
        // Heart metrics
        let baseRHR = 58
        let baseHRV = 65
        let rhr = baseRHR + random.int(in: -5...5) - (sleepDuration < 6.5 ? random.int(in: 5...10) : 0)
        let hrv = baseHRV + random.int(in: -10...10) - (sleepDuration < 6.5 ? random.int(in: 15...25) : 0)
        let rr = random.double(in: 13.5...16.5)
        
        let heartData = HeartMetrics(
            restingHeartRate: rhr,
            heartRateVariability: max(30, hrv),
            respiratoryRate: rr
        )
        
        // Sleep metrics
        let deepSleep = Int(sleepDuration * 60 * random.double(in: 0.15...0.25))
        let remSleep = Int(sleepDuration * 60 * random.double(in: 0.20...0.30))
        let awakeTime = Int(sleepDuration * 60 * (1 - sleepEff / 100))
        
        let sleepData = SleepMetrics(
            totalDuration: sleepDuration,
            sleepEfficiency: sleepEff,
            deepSleepMinutes: deepSleep,
            remSleepMinutes: remSleep,
            awakeMinutes: awakeTime
        )
        
        // Activity metrics
        let steps = isWorkoutDay ? random.int(in: 8000...15000) : random.int(in: 4000...8000)
        let activeEnergy = Double(steps) * random.double(in: 0.04...0.06)
        
        let activityData = ActivityMetrics(
            strain: strainValue,
            recovery: recoveryValue,
            energyCapacity: (recoveryValue * 0.7) + (sleepEff * 0.3),
            activeEnergyBurned: activeEnergy,
            steps: steps
        )
        
        // Vitals
        let vitalsData = VitalsMetrics(
            oxygenSaturation: random.int(in: 96...99),
            bodyTemperature: random.double(in: 97.8...98.6),
            bloodGlucose: random.double(in: 85...105)
        )
        
        return DailyMetrics(
            date: date,
            heartData: heartData,
            sleepData: sleepData,
            activityData: activityData,
            vitalsData: vitalsData,
            activityStatus: status
        )
    }
    
    /// Generate journal entry with realistic habit patterns
    private func generateJournalEntry(for date: Date, phase: NarrativePhase, random: inout SeededRandomGenerator) -> JournalEntry {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let isWeekend = (dayOfWeek == 1 || dayOfWeek == 7)
        let isWorkoutDay = (dayOfWeek == 2 || dayOfWeek == 4 || dayOfWeek == 6)
        
        var entry = JournalEntry(date: date)
        
        // Manual habits with realistic patterns
        entry.caffeine = random.bool(probability: 0.85)  // Most days
        entry.hydration = random.bool(probability: 0.70)
        entry.addedSugar = isWeekend ? random.bool(probability: 0.4) : random.bool(probability: 0.2)
        entry.alcohol = isWeekend ? random.bool(probability: 0.5) : random.bool(probability: 0.15)
        entry.deviceInBed = random.bool(probability: 0.3)
        entry.lateMeal = random.bool(probability: 0.25)
        entry.keto = random.bool(probability: 0.4)
        entry.lowCarbs = random.bool(probability: 0.5)
        
        // Automatic triggers based on phase
        switch phase {
        case .injured:
            entry.steps10k = false
            entry.cardio20min = false
            entry.strength20min = false
            entry.daylight20min = random.bool(probability: 0.3)
            
        case .recovery:
            entry.steps10k = isWorkoutDay ? random.bool(probability: 0.6) : false
            entry.steps10kSource = entry.steps10k ? .automatic(metric: "Step Count") : nil
            entry.cardio20min = isWorkoutDay ? random.bool(probability: 0.5) : false
            entry.cardio20minSource = entry.cardio20min ? .automatic(metric: "Cardio Workout") : nil
            entry.strength20min = isWorkoutDay ? random.bool(probability: 0.4) : false
            entry.strength20minSource = entry.strength20min ? .automatic(metric: "Strength Workout") : nil
            entry.daylight20min = random.bool(probability: 0.5)
            
        case .active:
            entry.steps10k = isWorkoutDay
            entry.steps10kSource = entry.steps10k ? .automatic(metric: "Step Count") : nil
            entry.cardio20min = (dayOfWeek == 2 || dayOfWeek == 6)  // Mon, Fri
            entry.cardio20minSource = entry.cardio20min ? .automatic(metric: "Cardio Workout") : nil
            entry.strength20min = (dayOfWeek == 4 || dayOfWeek == 6)  // Wed, Fri
            entry.strength20minSource = entry.strength20min ? .automatic(metric: "Strength Workout") : nil
            entry.daylight20min = random.bool(probability: 0.75)
            entry.daylight20minSource = entry.daylight20min ? .automatic(metric: "UV Exposure") : nil
        }
        
        entry.sleepingNoise50dB = random.bool(probability: 0.15)
        entry.sleepingNoise50dBSource = entry.sleepingNoise50dB ? .automatic(metric: "Environmental Audio") : nil
        
        return entry
    }
    
    /// Generate fitness volume with muscle group splits
    private func generateFitnessVolume(for date: Date, phase: NarrativePhase, random: inout SeededRandomGenerator) -> FitnessVolume {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let isWorkoutDay = (dayOfWeek == 2 || dayOfWeek == 4 || dayOfWeek == 6)
        
        var volume = FitnessVolume(date: date)
        
        switch phase {
        case .injured:
            volume.workoutCount = 0
            volume.cardioLoad = 0
            
        case .recovery:
            if isWorkoutDay {
                volume.workoutCount = random.int(in: 1...2)
                
                // Light volume
                if dayOfWeek == 2 {  // Monday: Upper body
                    volume.strengthVolumeChest = random.int(in: 4...8)
                    volume.strengthVolumeArms = random.int(in: 3...6)
                    volume.strengthVolumeShoulders = random.int(in: 3...6)
                } else if dayOfWeek == 4 {  // Wednesday: Lower body
                    volume.strengthVolumeLegs = random.int(in: 6...10)
                    volume.strengthVolumeCore = random.int(in: 3...5)
                } else if dayOfWeek == 6 {  // Friday: Full body
                    volume.strengthVolumeBack = random.int(in: 4...7)
                    volume.strengthVolumeCore = random.int(in: 3...5)
                }
                
                volume.cardioLoad = random.double(in: 20...40)
                volume.heartRateRecovery = random.int(in: 25...35)
            }
            
        case .active:
            if isWorkoutDay {
                volume.workoutCount = random.int(in: 2...3)
                
                // Structured splits
                if dayOfWeek == 2 {  // Monday: Push day
                    volume.strengthVolumeChest = random.int(in: 12...18)
                    volume.strengthVolumeShoulders = random.int(in: 10...15)
                    volume.strengthVolumeArms = random.int(in: 8...12)
                    volume.cardioLoad = random.double(in: 15...25)
                } else if dayOfWeek == 4 {  // Wednesday: Pull day
                    volume.strengthVolumeBack = random.int(in: 15...20)
                    volume.strengthVolumeArms = random.int(in: 8...12)
                    volume.strengthVolumeCore = random.int(in: 6...10)
                    volume.cardioLoad = random.double(in: 10...20)
                } else if dayOfWeek == 6 {  // Friday: Leg day + cardio
                    volume.strengthVolumeLegs = random.int(in: 18...24)
                    volume.strengthVolumeCore = random.int(in: 8...12)
                    volume.cardioLoad = random.double(in: 45...65)
                }
                
                volume.heartRateRecovery = random.int(in: 35...50)
            } else {
                volume.workoutCount = 0
                volume.cardioLoad = 0
            }
        }
        
        return volume
    }
    
    // MARK: - Data Loading
    
    /// Refresh state from cached SwiftData
    private func refreshFromCache() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch 90-day journal entries
        let journalDescriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        journalEntries = (try? modelContext.fetch(journalDescriptor)) ?? []
        
        // Fetch 30-day fitness volumes
        let fitnessDescriptor = FetchDescriptor<FitnessVolume>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        fitnessVolumes = (try? modelContext.fetch(fitnessDescriptor)) ?? []
        
        // Fetch today's metrics for dashboard
        let metricsDescriptor = FetchDescriptor<DailyMetrics>(
            predicate: #Predicate { $0.date >= today },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let todayMetrics = try? modelContext.fetch(metricsDescriptor).first {
            strain = todayMetrics.activityData.strain
            recovery = todayMetrics.activityData.recovery
            sleepHours = todayMetrics.sleepData.totalDuration ?? 0
            sleepEfficiency = todayMetrics.sleepData.sleepEfficiency ?? 0
            activityStatus = todayMetrics.activityStatus
            
            currentRHR = todayMetrics.heartData.restingHeartRate
            currentHRV = todayMetrics.heartData.heartRateVariability
            respiratoryRate = todayMetrics.heartData.respiratoryRate
            currentSpO2 = todayMetrics.vitalsData.oxygenSaturation
            bodyTemperature = todayMetrics.vitalsData.bodyTemperature
            bloodGlucose = todayMetrics.vitalsData.bloodGlucose
        }
        
        // Calculate biological age
        biologicalAge = calculateBiologicalAge()
        
        // Set mock biology baselines
        weight = 165.0
        bodyFatPercentage = 18.5
        leanBodyMass = 134.5
        vo2Max = 48.5
    }
    
    // MARK: - Chart Data Structures
    
    /// 30-day strain data for Charts framework
    var strainChartData: [IdentifiableChartPoint] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<DailyMetrics>(
            predicate: #Predicate { $0.date >= thirtyDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        guard let metrics = try? modelContext.fetch(descriptor) else { return [] }
        
        return metrics.map { metric in
            IdentifiableChartPoint(
                date: metric.date,
                value: metric.activityData.strain,
                label: metric.date.formatted(.dateTime.month(.abbreviated).day())
            )
        }
    }
    
    /// 30-day recovery data for Charts framework
    var recoveryChartData: [IdentifiableChartPoint] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<DailyMetrics>(
            predicate: #Predicate { $0.date >= thirtyDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        guard let metrics = try? modelContext.fetch(descriptor) else { return [] }
        
        return metrics.map { metric in
            IdentifiableChartPoint(
                date: metric.date,
                value: metric.activityData.recovery,
                label: metric.date.formatted(.dateTime.month(.abbreviated).day())
            )
        }
    }
    
    /// 90-day journal heatmap data (13 weeks × 7 days)
    var journalHeatmapData: [[Bool]] {
        var grid: [[Bool]] = []
        
        for weekOffset in (0..<13).reversed() {
            var week: [Bool] = []
            for dayOffset in 0..<7 {
                let totalOffset = -(weekOffset * 7 + dayOffset)
                let calendar = Calendar.current
                guard let date = calendar.date(byAdding: .day, value: totalOffset, to: Date()) else {
                    week.append(false)
                    continue
                }
                
                let hasEntry = journalEntries.contains { calendar.isDate($0.date, inSameDayAs: date) && $0.completedHabitsCount > 0 }
                week.append(hasEntry)
            }
            grid.append(week)
        }
        
        return grid
    }
    
    /// 30-day fitness activity grid (workout count per day)
    var fitnessActivityGrid: [[Int]] {
        var grid: [[Int]] = []
        let calendar = Calendar.current
        
        // Create 5 weeks × 7 days grid
        for weekOffset in (0..<5).reversed() {
            var week: [Int] = []
            for dayOffset in 0..<7 {
                let totalOffset = -(weekOffset * 7 + dayOffset)
                guard let date = calendar.date(byAdding: .day, value: totalOffset, to: Date()) else {
                    week.append(0)
                    continue
                }
                
                let workoutCount = fitnessVolumes.first { calendar.isDate($0.date, inSameDayAs: date) }?.workoutCount ?? 0
                week.append(workoutCount)
            }
            grid.append(week)
        }
        
        return grid
    }
    
    // MARK: - Biological Age Calculation
    
    /// Stub calculation for biological age (can be swapped with CoreML model later)
    func calculateBiologicalAge() -> Double {
        // Baseline: chronological age
        var age = chronologicalAge
        
        // Normalize RHR (lower is better)
        if let rhr = currentRHR {
            let normalizedRHR = (Double(rhr) - 60.0) / 10.0  // -1 to +1 range roughly
            age += normalizedRHR * 2.0
        }
        
        // Normalize HRV (higher is better)
        if let hrv = currentHRV {
            let normalizedHRV = (65.0 - Double(hrv)) / 20.0  // Inverted
            age += normalizedHRV * 1.5
        }
        
        // Normalize VO2 Max (higher is better)
        if let vo2 = vo2Max {
            let normalizedVO2 = (45.0 - vo2) / 10.0  // Inverted
            age += normalizedVO2 * 3.0
        }
        
        // Normalize recovery (higher is better)
        let normalizedRecovery = (75.0 - recovery) / 15.0  // Inverted
        age += normalizedRecovery * 1.0
        
        return max(chronologicalAge - 10, min(chronologicalAge + 10, age))
    }
    
    // MARK: - Real Data Pipeline
    
    /// Setup real HealthKit connectivity
    private func setupRealDataPipeline() async {
        // Request HealthKit auth
        await requestHealthKitAuthorization()
        
        // Start observing background HealthKit changes
        if healthKitAuthorized {
            HealthKitManager.shared.startObservingHealthChanges { [weak self] type in
                guard let self = self else { return }
                Task {
                    await self.refreshHealthData()
                }
            }
        }
    }
    
    /// Refresh health data from HealthKit
    func refreshHealthData() async {
        guard !isMocked, healthKitAuthorized else { return }
        do {
            let todayMetrics = try await HealthKitManager.shared.fetchDailyMetrics(for: Date())
            
            // Save to SwiftData
            modelContext.insert(todayMetrics)
            try? modelContext.save()
            
            // Update UI Properties
            self.strain = todayMetrics.activityData.strain
            self.recovery = todayMetrics.activityData.recovery
            self.sleepHours = todayMetrics.sleepData.totalDuration ?? 0
            self.sleepEfficiency = todayMetrics.sleepData.sleepEfficiency ?? 0
            self.activityStatus = todayMetrics.activityStatus
            
            self.currentRHR = todayMetrics.heartData.restingHeartRate
            self.currentHRV = todayMetrics.heartData.heartRateVariability
            self.respiratoryRate = todayMetrics.heartData.respiratoryRate
            self.currentSpO2 = todayMetrics.vitalsData.oxygenSaturation
            self.bodyTemperature = todayMetrics.vitalsData.bodyTemperature
            self.bloodGlucose = todayMetrics.vitalsData.bloodGlucose
            
            self.biologicalAge = calculateBiologicalAge()
            
            // Set mock biology baselines if nil
            if self.weight == nil { self.weight = 165.0 }
            if self.bodyFatPercentage == nil { self.bodyFatPercentage = 18.5 }
            if self.leanBodyMass == nil { self.leanBodyMass = 134.5 }
            if self.vo2Max == nil { self.vo2Max = 48.5 }
        } catch {
            print("❌ Failed to fetch real daily metrics: \(error)")
        }
    }
    
    /// Fetch real-time vitals (Health Monitor tab)
    func fetchRealtimeVitals() async {
        guard !isMocked else { return }
        await refreshHealthData()
    }
    
    /// Request HealthKit authorization
    func requestHealthKitAuthorization() async {
        guard !isMocked else { return }
        do {
            let authorized = try await HealthKitManager.shared.requestAuthorization()
            self.healthKitAuthorized = authorized
            if authorized {
                await refreshHealthData()
            }
        } catch {
            self.authorizationError = error.localizedDescription
            print("❌ HealthKit setup error: \(error)")
        }
    }
    
    /// Force refresh bypassing cache
    func forceRefresh() async {
        if isMocked {
            refreshFromCache()
        } else {
            await refreshHealthData()
        }
    }
}

// MARK: - Narrative Phase

/// Story arc phases for mock data generation
private enum NarrativePhase {
    case injured    // Days 1-14: Low activity, poor metrics
    case recovery   // Days 15-30: Gradual improvement
    case active     // Days 31-90: Consistent training pattern
}

// MARK: - Seeded Random Generator

/// Deterministic random number generator for reproducible mock data
private struct SeededRandomGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    
    mutating func double(in range: ClosedRange<Double>) -> Double {
        let normalized = Double(next() % 10000) / 10000.0
        return range.lowerBound + (normalized * (range.upperBound - range.lowerBound))
    }
    
    mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        return range.lowerBound + Int(next() % UInt64(span))
    }
    
    mutating func bool(probability: Double) -> Bool {
        double(in: 0...1) < probability
    }
}

//
//  Models.swift
//  BevelClone
//
//  Core SwiftData models and enums for health tracking
//  Phase 1: Backend Foundation
//

import Foundation
import SwiftData

// MARK: - Activity Status

/// Current activity state of the user
enum ActivityStatus: String, Codable, CaseIterable {
    case active = "Active"
    case sick = "Sick"
    case injured = "Injured"
    case onBreak = "On a Break"
    
    var emoji: String {
        switch self {
        case .active: return "💪"
        case .sick: return "🤒"
        case .injured: return "🩹"
        case .onBreak: return "🏖️"
        }
    }
}

// MARK: - Muscle Groups

/// Anatomical muscle group categories for strength training tracking
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Chest"
    case arms = "Arms"
    case back = "Back"
    case core = "Core"
    case legs = "Legs"
    case shoulders = "Shoulders"
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .arms: return "figure.arms.open"
        case .back: return "figure.stand"
        case .core: return "figure.core.training"
        case .legs: return "figure.walk"
        case .shoulders: return "figure.flexibility"
        }
    }
}

// MARK: - Journal Habits

/// All trackable habits for the journal system
enum JournalHabit: String, Codable, CaseIterable {
    // Manual daytime habits
    case addedSugar = "Added Sugar"
    case alcohol = "Alcohol"
    case caffeine = "Caffeine"
    case hydration = "Hydration"
    case keto = "Keto"
    case lowCarbs = "Low Carbs"
    
    // Manual nighttime habits
    case deviceInBed = "Device in Bed"
    case lateMeal = "Late Meal"
    
    // Automatic HealthKit-triggered habits
    case steps10k = "10,000+ Steps"
    case cardio20min = "20+ Min Cardio"
    case strength20min = "20+ Min Strength"
    case daylight20min = "20+ Min Daylight"
    case sleepingNoise50dB = "50+ dB Sleeping Noise"
    
    var isAutomatic: Bool {
        switch self {
        case .steps10k, .cardio20min, .strength20min, .daylight20min, .sleepingNoise50dB:
            return true
        default:
            return false
        }
    }
    
    var category: String {
        switch self {
        case .addedSugar, .alcohol, .caffeine, .hydration, .keto, .lowCarbs:
            return "Daytime"
        case .deviceInBed, .lateMeal:
            return "Nighttime"
        default:
            return "Automatic"
        }
    }
}

// MARK: - Trigger Source

/// Tracks whether a journal entry was manually logged or automatically triggered
enum TriggerSource: Codable, Equatable {
    case manual
    case automatic(metric: String)
    
    var description: String {
        switch self {
        case .manual:
            return "Manually logged"
        case .automatic(let metric):
            return "Auto-detected: \(metric)"
        }
    }
}

// MARK: - Nested Codable Structs

/// Heart-related health metrics
struct HeartMetrics: Codable, Equatable {
    var restingHeartRate: Int?          // bpm
    var heartRateVariability: Int?      // ms (SDNN)
    var respiratoryRate: Double?        // breaths/min
    
    init(restingHeartRate: Int? = nil, heartRateVariability: Int? = nil, respiratoryRate: Double? = nil) {
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.respiratoryRate = respiratoryRate
    }
}

/// Sleep analysis metrics
struct SleepMetrics: Codable, Equatable {
    var totalDuration: Double?          // hours
    var sleepEfficiency: Double?        // percentage (0-100)
    var deepSleepMinutes: Int?
    var remSleepMinutes: Int?
    var awakeMinutes: Int?
    
    init(totalDuration: Double? = nil, sleepEfficiency: Double? = nil, deepSleepMinutes: Int? = nil, remSleepMinutes: Int? = nil, awakeMinutes: Int? = nil) {
        self.totalDuration = totalDuration
        self.sleepEfficiency = sleepEfficiency
        self.deepSleepMinutes = deepSleepMinutes
        self.remSleepMinutes = remSleepMinutes
        self.awakeMinutes = awakeMinutes
    }
}

/// Activity and recovery metrics
struct ActivityMetrics: Codable, Equatable {
    var strain: Double                  // percentage (0-100)
    var recovery: Double                // percentage (0-100)
    var energyCapacity: Double          // percentage (0-100)
    var activeEnergyBurned: Double?     // kcal
    var steps: Int?
    
    init(strain: Double = 0, recovery: Double = 0, energyCapacity: Double = 0, activeEnergyBurned: Double? = nil, steps: Int? = nil) {
        self.strain = strain
        self.recovery = recovery
        self.energyCapacity = energyCapacity
        self.activeEnergyBurned = activeEnergyBurned
        self.steps = steps
    }
}

/// Vitals and biomarkers
struct VitalsMetrics: Codable, Equatable {
    var oxygenSaturation: Int?          // percentage (0-100)
    var bodyTemperature: Double?        // Fahrenheit
    var bloodGlucose: Double?           // mg/dL
    
    init(oxygenSaturation: Int? = nil, bodyTemperature: Double? = nil, bloodGlucose: Double? = nil) {
        self.oxygenSaturation = oxygenSaturation
        self.bodyTemperature = bodyTemperature
        self.bloodGlucose = bloodGlucose
    }
}

// MARK: - Chart Data Point (for SwiftUI Charts compatibility)

/// Identifiable data point for Charts framework
struct ChartDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let value: Double
    let label: String
    let description: String
    
    init(id: UUID = UUID(), date: Date, value: Double, label: String, description: String) {
        self.id = id
        self.date = date
        self.value = value
        self.label = label
        self.description = description
    }
}

// MARK: - DailyMetrics Model

/// Comprehensive daily health metrics cached from HealthKit
@Model
final class DailyMetrics {
    @Attribute(.unique) var date: Date
    var heartData: HeartMetrics
    var sleepData: SleepMetrics
    var activityData: ActivityMetrics
    var vitalsData: VitalsMetrics
    var activityStatus: ActivityStatus
    var lastUpdated: Date
    
    init(date: Date, heartData: HeartMetrics = HeartMetrics(), sleepData: SleepMetrics = SleepMetrics(), activityData: ActivityMetrics = ActivityMetrics(), vitalsData: VitalsMetrics = VitalsMetrics(), activityStatus: ActivityStatus = .active, lastUpdated: Date = Date()) {
        self.date = date
        self.heartData = heartData
        self.sleepData = sleepData
        self.activityData = activityData
        self.vitalsData = vitalsData
        self.activityStatus = activityStatus
        self.lastUpdated = lastUpdated
    }
    
    /// Normalized date (midnight UTC) for deduplication
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Convert strain data to chart-compatible format
    var strainChartPoint: ChartDataPoint {
        ChartDataPoint(
            date: date,
            value: activityData.strain,
            label: date.formatted(.dateTime.month(.abbreviated).day()),
            description: "Strain: \(Int(activityData.strain))%"
        )
    }
    
    /// Convert recovery data to chart-compatible format
    var recoveryChartPoint: ChartDataPoint {
        ChartDataPoint(
            date: date,
            value: activityData.recovery,
            label: date.formatted(.dateTime.month(.abbreviated).day()),
            description: "Recovery: \(Int(activityData.recovery))%"
        )
    }
}

// MARK: - JournalEntry Model

/// Daily habit tracking with automatic HealthKit triggers
@Model
final class JournalEntry {
    @Attribute(.unique) var date: Date
    
    // Manual daytime habits
    var addedSugar: Bool
    var alcohol: Bool
    var caffeine: Bool
    var hydration: Bool
    var keto: Bool
    var lowCarbs: Bool
    
    // Manual nighttime habits
    var deviceInBed: Bool
    var lateMeal: Bool
    
    // Automatic HealthKit-triggered habits
    var steps10k: Bool
    var steps10kSource: TriggerSource?
    
    var cardio20min: Bool
    var cardio20minSource: TriggerSource?
    
    var strength20min: Bool
    var strength20minSource: TriggerSource?
    
    var daylight20min: Bool
    var daylight20minSource: TriggerSource?
    
    var sleepingNoise50dB: Bool
    var sleepingNoise50dBSource: TriggerSource?
    
    var lastUpdated: Date
    
    init(date: Date, addedSugar: Bool = false, alcohol: Bool = false, caffeine: Bool = false, hydration: Bool = false, keto: Bool = false, lowCarbs: Bool = false, deviceInBed: Bool = false, lateMeal: Bool = false, steps10k: Bool = false, steps10kSource: TriggerSource? = nil, cardio20min: Bool = false, cardio20minSource: TriggerSource? = nil, strength20min: Bool = false, strength20minSource: TriggerSource? = nil, daylight20min: Bool = false, daylight20minSource: TriggerSource? = nil, sleepingNoise50dB: Bool = false, sleepingNoise50dBSource: TriggerSource? = nil, lastUpdated: Date = Date()) {
        self.date = date
        self.addedSugar = addedSugar
        self.alcohol = alcohol
        self.caffeine = caffeine
        self.hydration = hydration
        self.keto = keto
        self.lowCarbs = lowCarbs
        self.deviceInBed = deviceInBed
        self.lateMeal = lateMeal
        self.steps10k = steps10k
        self.steps10kSource = steps10kSource
        self.cardio20min = cardio20min
        self.cardio20minSource = cardio20minSource
        self.strength20min = strength20min
        self.strength20minSource = strength20minSource
        self.daylight20min = daylight20min
        self.daylight20minSource = daylight20minSource
        self.sleepingNoise50dB = sleepingNoise50dB
        self.sleepingNoise50dBSource = sleepingNoise50dBSource
        self.lastUpdated = lastUpdated
    }
    
    /// Normalized date (midnight UTC) for deduplication
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Count of successful habits for the day
    var completedHabitsCount: Int {
        var count = 0
        if addedSugar { count += 1 }
        if alcohol { count += 1 }
        if caffeine { count += 1 }
        if hydration { count += 1 }
        if keto { count += 1 }
        if lowCarbs { count += 1 }
        if deviceInBed { count += 1 }
        if lateMeal { count += 1 }
        if steps10k { count += 1 }
        if cardio20min { count += 1 }
        if strength20min { count += 1 }
        if daylight20min { count += 1 }
        if sleepingNoise50dB { count += 1 }
        return count
    }
    
    /// Check if a specific habit is completed
    func isCompleted(_ habit: JournalHabit) -> Bool {
        switch habit {
        case .addedSugar: return addedSugar
        case .alcohol: return alcohol
        case .caffeine: return caffeine
        case .hydration: return hydration
        case .keto: return keto
        case .lowCarbs: return lowCarbs
        case .deviceInBed: return deviceInBed
        case .lateMeal: return lateMeal
        case .steps10k: return steps10k
        case .cardio20min: return cardio20min
        case .strength20min: return strength20min
        case .daylight20min: return daylight20min
        case .sleepingNoise50dB: return sleepingNoise50dB
        }
    }
    
    /// Set a habit's completion status
    mutating func setCompleted(_ habit: JournalHabit, completed: Bool, source: TriggerSource = .manual) {
        switch habit {
        case .addedSugar: addedSugar = completed
        case .alcohol: alcohol = completed
        case .caffeine: caffeine = completed
        case .hydration: hydration = completed
        case .keto: keto = completed
        case .lowCarbs: lowCarbs = completed
        case .deviceInBed: deviceInBed = completed
        case .lateMeal: lateMeal = completed
        case .steps10k:
            steps10k = completed
            steps10kSource = completed ? source : nil
        case .cardio20min:
            cardio20min = completed
            cardio20minSource = completed ? source : nil
        case .strength20min:
            strength20min = completed
            strength20minSource = completed ? source : nil
        case .daylight20min:
            daylight20min = completed
            daylight20minSource = completed ? source : nil
        case .sleepingNoise50dB:
            sleepingNoise50dB = completed
            sleepingNoise50dBSource = completed ? source : nil
        }
        lastUpdated = Date()
    }
}

// MARK: - FitnessVolume Model

/// Daily fitness activity tracking with muscle group volume
@Model
final class FitnessVolume {
    @Attribute(.unique) var date: Date
    var workoutCount: Int                           // 0, 1, 2, 3+ for heatmap coloring
    var strengthVolumeChest: Int                    // sets
    var strengthVolumeArms: Int
    var strengthVolumeBack: Int
    var strengthVolumeCore: Int
    var strengthVolumeLegs: Int
    var strengthVolumeShoulders: Int
    var cardioLoad: Double                          // arbitrary units (duration × intensity)
    var heartRateRecovery: Int?                     // bpm decrease in first minute post-workout
    var lastUpdated: Date
    
    init(date: Date, workoutCount: Int = 0, strengthVolumeChest: Int = 0, strengthVolumeArms: Int = 0, strengthVolumeBack: Int = 0, strengthVolumeCore: Int = 0, strengthVolumeLegs: Int = 0, strengthVolumeShoulders: Int = 0, cardioLoad: Double = 0, heartRateRecovery: Int? = nil, lastUpdated: Date = Date()) {
        self.date = date
        self.workoutCount = workoutCount
        self.strengthVolumeChest = strengthVolumeChest
        self.strengthVolumeArms = strengthVolumeArms
        self.strengthVolumeBack = strengthVolumeBack
        self.strengthVolumeCore = strengthVolumeCore
        self.strengthVolumeLegs = strengthVolumeLegs
        self.strengthVolumeShoulders = strengthVolumeShoulders
        self.cardioLoad = cardioLoad
        self.heartRateRecovery = heartRateRecovery
        self.lastUpdated = lastUpdated
    }
    
    /// Normalized date (midnight UTC) for deduplication
    var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Get volume for a specific muscle group
    func volume(for muscleGroup: MuscleGroup) -> Int {
        switch muscleGroup {
        case .chest: return strengthVolumeChest
        case .arms: return strengthVolumeArms
        case .back: return strengthVolumeBack
        case .core: return strengthVolumeCore
        case .legs: return strengthVolumeLegs
        case .shoulders: return strengthVolumeShoulders
        }
    }
    
    /// Set volume for a specific muscle group
    func setVolume(for muscleGroup: MuscleGroup, sets: Int) {
        switch muscleGroup {
        case .chest: strengthVolumeChest = sets
        case .arms: strengthVolumeArms = sets
        case .back: strengthVolumeBack = sets
        case .core: strengthVolumeCore = sets
        case .legs: strengthVolumeLegs = sets
        case .shoulders: strengthVolumeShoulders = sets
        }
        lastUpdated = Date()
    }
    
    /// Total strength volume across all muscle groups
    var totalStrengthVolume: Int {
        strengthVolumeChest + strengthVolumeArms + strengthVolumeBack + strengthVolumeCore + strengthVolumeLegs + strengthVolumeShoulders
    }
    
    /// Heatmap intensity category (0 = rest, 1 = light, 2 = moderate, 3+ = heavy)
    var heatmapIntensity: Int {
        min(workoutCount, 3)
    }
}

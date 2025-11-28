//
//  UserProfile.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: String
    var stravaId: Int?
    var igpsportId: String?
    var name: String
    var weight: Double? // kg
    var ftp: Double? // watts
    var maxHeartRate: Int? // bpm
    var restingHeartRate: Int? // bpm
    var lactateThresholdHR: Int? // LTHR for hrTSS calculations
    var heartRateZones: [Int] // Zone boundaries [Z1_max, Z2_max, Z3_max, Z4_max] (Z5 is maxHR)
    var powerZones: [Double] // Zone boundaries based on FTP [Z1_max, Z2_max, Z3_max, Z4_max, Z5_max, Z6_max] (Z7 is unlimited)
    var preferences: UserPreferences
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        weight: Double? = nil,
        ftp: Double? = nil,
        maxHeartRate: Int? = nil,
        restingHeartRate: Int? = nil,
        lactateThresholdHR: Int? = nil,
        heartRateZones: [Int] = [],
        powerZones: [Double] = [],
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.name = name
        self.weight = weight
        self.ftp = ftp
        self.maxHeartRate = maxHeartRate
        self.restingHeartRate = restingHeartRate
        self.lactateThresholdHR = lactateThresholdHR
        self.heartRateZones = heartRateZones
        self.powerZones = powerZones
        self.preferences = preferences
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Helper methods for zone calculations
    func calculatePowerZones() {
        guard let ftp = ftp else { return }
        powerZones = [
            ftp * 0.55, // Z1: Active Recovery (< 55% FTP)
            ftp * 0.75, // Z2: Endurance (55-75% FTP)
            ftp * 0.90, // Z3: Tempo (76-90% FTP)
            ftp * 1.05, // Z4: Lactate Threshold (91-105% FTP)
            ftp * 1.20, // Z5: VO2 Max (106-120% FTP)
            ftp * 1.50  // Z6: Anaerobic Capacity (121-150% FTP)
            // Z7: Neuromuscular Power (> 150% FTP)
        ]
    }
    
    func calculateHeartRateZones() {
        guard let maxHR = maxHeartRate, let restingHR = restingHeartRate else { return }
        let hrReserve = maxHR - restingHR
        heartRateZones = [
            restingHR + Int(Double(hrReserve) * 0.60), // Z1: < 60% HRR
            restingHR + Int(Double(hrReserve) * 0.70), // Z2: 60-70% HRR
            restingHR + Int(Double(hrReserve) * 0.80), // Z3: 70-80% HRR
            restingHR + Int(Double(hrReserve) * 0.90)  // Z4: 80-90% HRR
            // Z5: 90-100% HRR (up to maxHR)
        ]
    }
}

@Model
final class UserPreferences {
    var units: UnitSystem
    var autoSync: Bool
    var syncInterval: TimeInterval // seconds
    var aiAnalysisEnabled: Bool
    var aiProvider: String
    var privacyLevel: PrivacyLevel
    
    init(
        units: UnitSystem = .metric,
        autoSync: Bool = true,
        syncInterval: TimeInterval = 3600, // 1 hour
        aiAnalysisEnabled: Bool = true,
        aiProvider: String = "deepseek",
        privacyLevel: PrivacyLevel = .standard
    ) {
        self.units = units
        self.autoSync = autoSync
        self.syncInterval = syncInterval
        self.aiAnalysisEnabled = aiAnalysisEnabled
        self.aiProvider = aiProvider
        self.privacyLevel = privacyLevel
    }
}

enum UnitSystem: String, Codable, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"
    
    var displayName: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }
}

enum PrivacyLevel: String, Codable, CaseIterable {
    case minimal = "minimal"
    case standard = "standard"
    case full = "full"
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal Data Sharing"
        case .standard: return "Standard Privacy"
        case .full: return "Full Data Sharing"
        }
    }
}
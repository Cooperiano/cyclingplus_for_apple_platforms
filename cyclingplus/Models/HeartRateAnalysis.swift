//
//  HeartRateAnalysis.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

@Model
final class HeartRateAnalysis {
    var activityId: String
    var heartRateZones: [HRZoneData]
    var hrTSS: Double? // Heart Rate Training Stress Score
    var estimatedVO2Max: Double?
    var averageHR: Int?
    var maxHR: Int?
    var restingHR: Int?
    var hrReserve: Int? // Max HR - Resting HR
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship back to activity
    var activity: Activity?
    
    init(
        activityId: String,
        heartRateZones: [HRZoneData] = [],
        hrTSS: Double? = nil,
        estimatedVO2Max: Double? = nil,
        averageHR: Int? = nil,
        maxHR: Int? = nil,
        restingHR: Int? = nil,
        hrReserve: Int? = nil
    ) {
        self.activityId = activityId
        self.heartRateZones = heartRateZones
        self.hrTSS = hrTSS
        self.estimatedVO2Max = estimatedVO2Max
        self.averageHR = averageHR
        self.maxHR = maxHR
        self.restingHR = restingHR
        self.hrReserve = hrReserve
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class HRZoneData {
    var zone: Int // 1-5 heart rate zones
    var timeInZone: TimeInterval // seconds
    var percentageInZone: Double // 0-100
    var averageHRInZone: Int?
    var minHR: Int? // Zone boundaries
    var maxHR: Int?
    
    init(
        zone: Int,
        timeInZone: TimeInterval,
        percentageInZone: Double,
        averageHRInZone: Int? = nil,
        minHR: Int? = nil,
        maxHR: Int? = nil
    ) {
        self.zone = zone
        self.timeInZone = timeInZone
        self.percentageInZone = percentageInZone
        self.averageHRInZone = averageHRInZone
        self.minHR = minHR
        self.maxHR = maxHR
    }
}
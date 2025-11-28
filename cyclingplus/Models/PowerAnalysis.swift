//
//  PowerAnalysis.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

@Model
final class PowerAnalysis {
    var activityId: String
    var eFTP: Double? // estimated Functional Threshold Power
    var criticalPower: Double? // CP from CP/W' model
    var wPrime: Double? // W' from CP/W' model
    var normalizedPower: Double? // NP
    var intensityFactor: Double? // IF
    var trainingStressScore: Double? // TSS
    var variabilityIndex: Double? // VI
    var efficiencyFactor: Double? // EF
    var averagePower: Double?
    var maxPower: Double?
    var powerZones: [PowerZoneData]
    var meanMaximalPower: [MMPPoint]
    var wPrimeBalance: [Double]?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship back to activity
    var activity: Activity?
    
    init(
        activityId: String,
        eFTP: Double? = nil,
        criticalPower: Double? = nil,
        wPrime: Double? = nil,
        normalizedPower: Double? = nil,
        intensityFactor: Double? = nil,
        trainingStressScore: Double? = nil,
        variabilityIndex: Double? = nil,
        efficiencyFactor: Double? = nil,
        averagePower: Double? = nil,
        maxPower: Double? = nil,
        powerZones: [PowerZoneData] = [],
        meanMaximalPower: [MMPPoint] = [],
        wPrimeBalance: [Double]? = nil
    ) {
        self.activityId = activityId
        self.eFTP = eFTP
        self.criticalPower = criticalPower
        self.wPrime = wPrime
        self.normalizedPower = normalizedPower
        self.intensityFactor = intensityFactor
        self.trainingStressScore = trainingStressScore
        self.variabilityIndex = variabilityIndex
        self.efficiencyFactor = efficiencyFactor
        self.averagePower = averagePower
        self.maxPower = maxPower
        self.powerZones = powerZones
        self.meanMaximalPower = meanMaximalPower
        self.wPrimeBalance = wPrimeBalance
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class PowerZoneData {
    var zone: Int // 1-7 power zones
    var timeInZone: TimeInterval // seconds
    var percentageInZone: Double // 0-100
    var averagePowerInZone: Double?
    
    init(zone: Int, timeInZone: TimeInterval, percentageInZone: Double, averagePowerInZone: Double? = nil) {
        self.zone = zone
        self.timeInZone = timeInZone
        self.percentageInZone = percentageInZone
        self.averagePowerInZone = averagePowerInZone
    }
}

@Model
final class MMPPoint {
    var duration: TimeInterval // seconds
    var power: Double // watts
    
    init(duration: TimeInterval, power: Double) {
        self.duration = duration
        self.power = power
    }
}
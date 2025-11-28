//
//  PowerAnalysisService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation

/// Service for calculating power-based performance metrics
class PowerAnalysisService {
    
    // MARK: - Public Methods
    
    /// Calculate comprehensive power metrics from activity streams
    func calculatePowerMetrics(from streams: ActivityStreams, userFTP: Double? = nil, userPowerZones: [Double]? = nil) -> PowerAnalysis {
        let (timeData, powerData) = streams.powerTimeSeries()
        guard !powerData.isEmpty else {
            return PowerAnalysis(activityId: streams.activityId)
        }

        let analysis = PowerAnalysis(activityId: streams.activityId)
        
        // Basic power statistics
        analysis.averagePower = calculateAveragePower(powerData: powerData)
        analysis.maxPower = powerData.max()
        
        // Normalized Power (NP)
        analysis.normalizedPower = calculateNormalizedPower(powerData: powerData, timeData: timeData)
        
        // Estimate FTP if not provided
        let ftp = userFTP ?? estimateFTP(powerData: powerData, duration: timeData.last ?? 0)
        analysis.eFTP = ftp
        
        // Calculate IF, TSS, VI if we have FTP
        if let np = analysis.normalizedPower, ftp > 0 {
            analysis.intensityFactor = calculateIntensityFactor(normalizedPower: np, ftp: ftp)
            
            if let intensity = analysis.intensityFactor {
                let duration = timeData.last ?? 0
                analysis.trainingStressScore = calculateTSS(
                    normalizedPower: np,
                    intensityFactor: intensity,
                    duration: duration,
                    ftp: ftp
                )
            }
            
            if let avgPower = analysis.averagePower {
                analysis.variabilityIndex = calculateVariabilityIndex(
                    normalizedPower: np,
                    averagePower: avgPower
                )
            }
        }
        
        // Efficiency Factor (requires heart rate data)
        if let hrData = streams.heartRateData,
           let np = analysis.normalizedPower {
            let hrValues = hrData.compactMap { $0 }
            if !hrValues.isEmpty {
                let avgHR = Double(hrValues.reduce(0, +)) / Double(hrValues.count)
                analysis.efficiencyFactor = calculateEfficiencyFactor(
                    normalizedPower: np,
                    averageHeartRate: avgHR
                )
            }
        }
        
        // Power zone distribution analysis
        if ftp > 0 {
            let zones = userPowerZones ?? generateDefaultPowerZones(ftp: ftp)
            analysis.powerZones = calculatePowerZoneDistribution(
                powerData: powerData,
                timeData: timeData,
                zoneThresholds: zones
            )
        }
        
        // Mean Maximal Power curve
        analysis.meanMaximalPower = calculateMeanMaximalPower(powerData: powerData, timeData: timeData)
        
        // Critical Power and W' balance
        if let cpResult = calculateCriticalPower(powerData: powerData, timeData: timeData) {
            analysis.criticalPower = cpResult.cp
            analysis.wPrime = cpResult.wPrime
            analysis.wPrimeBalance = calculateWPrimeBalance(
                powerData: powerData,
                timeData: timeData,
                cp: cpResult.cp,
                wPrime: cpResult.wPrime
            )
        }
        
        return analysis
    }
    
    /// Estimate FTP from activity data using various methods
    func estimateFTP(from activities: [Activity]) -> Double? {
        // Collect all power analyses
        let powerAnalyses = activities.compactMap { $0.powerAnalysis }
        guard !powerAnalyses.isEmpty else { return nil }
        
        // Method 1: Use 95% of best 20-minute power
        var best20MinPower: Double?
        
        for activity in activities {
            guard let streams = activity.streams,
                  activity.duration >= 1200 else { continue } // At least 20 minutes
            
            let (timeSeries, powerSeries) = streams.powerTimeSeries()
            guard !powerSeries.isEmpty else { continue }
            
            let mmp = calculateMeanMaximalPower(powerData: powerSeries, timeData: timeSeries)
            if let power20Min = mmp.first(where: { $0.duration == 1200 })?.power {
                if best20MinPower == nil || power20Min > best20MinPower! {
                    best20MinPower = power20Min
                }
            }
        }
        
        if let best20 = best20MinPower {
            return best20 * 0.95
        }
        
        return nil
    }
    
    /// Calculate Critical Power and W' from power data
    func calculateCriticalPower(powerData: [Double], timeData: [Double]) -> (cp: Double, wPrime: Double)? {
        guard powerData.count == timeData.count, powerData.count > 0 else { return nil }
        
        // Use 2-parameter CP model: Time = W'/(P - CP)
        // We'll use 3 and 12 minute efforts for the calculation
        let mmp = calculateMeanMaximalPower(powerData: powerData, timeData: timeData)
        
        guard let power3Min = mmp.first(where: { $0.duration == 180 })?.power,
              let power12Min = mmp.first(where: { $0.duration == 720 })?.power else {
            return nil
        }
        
        // Linear regression: W = CP * t + W'
        // W3 = power3Min * 180, W12 = power12Min * 720
        let t1 = 180.0
        let t2 = 720.0
        let w1 = power3Min * t1
        let w2 = power12Min * t2
        
        // CP = (W2 - W1) / (t2 - t1)
        let cp = (w2 - w1) / (t2 - t1)
        
        // W' = W1 - CP * t1
        let wPrime = w1 - cp * t1
        
        return (cp: max(0, cp), wPrime: max(0, wPrime))
    }
    
    /// Calculate Mean Maximal Power curve
    func calculateMeanMaximalPower(powerData: [Double], timeData: [Double]) -> [MMPPoint] {
        guard powerData.count == timeData.count, powerData.count > 0 else { return [] }
        
        var mmpPoints: [MMPPoint] = []
        
        // Calculate MMP for standard durations
        let durations = [5, 10, 15, 30, 60, 120, 180, 300, 600, 1200, 1800, 3600, 5400, 7200]
        
        for duration in durations {
            if let maxAvgPower = calculateMaxAveragePower(
                powerData: powerData,
                timeData: timeData,
                duration: TimeInterval(duration)
            ) {
                mmpPoints.append(MMPPoint(duration: TimeInterval(duration), power: maxAvgPower))
            }
        }
        
        return mmpPoints
    }
    
    /// Calculate W' balance throughout the activity
    func calculateWPrimeBalance(powerData: [Double], timeData: [Double], cp: Double, wPrime: Double) -> [Double] {
        guard powerData.count == timeData.count, powerData.count > 0 else { return [] }
        
        var wBalance: [Double] = []
        var currentWPrime = wPrime
        
        for i in 0..<powerData.count {
            let power = powerData[i]
            let dt = i > 0 ? timeData[i] - timeData[i-1] : 1.0
            
            if power > cp {
                // Depleting W'
                let wExpended = (power - cp) * dt
                currentWPrime = max(0, currentWPrime - wExpended)
            } else {
                // Recovering W'
                let recoveryRate = (cp - power) / cp
                let wRecovered = wPrime * recoveryRate * dt / 546.0 // Tau = 546s
                currentWPrime = min(wPrime, currentWPrime + wRecovered)
            }
            
            wBalance.append(currentWPrime)
        }
        
        return wBalance
    }
    
    // MARK: - Private Helper Methods
    
    /// Generate default power zones based on FTP
    private func generateDefaultPowerZones(ftp: Double) -> [Double] {
        return [
            ftp * 0.55, // Z1: Active Recovery (< 55% FTP)
            ftp * 0.75, // Z2: Endurance (55-75% FTP)
            ftp * 0.90, // Z3: Tempo (76-90% FTP)
            ftp * 1.05, // Z4: Lactate Threshold (91-105% FTP)
            ftp * 1.20, // Z5: VO2 Max (106-120% FTP)
            ftp * 1.50  // Z6: Anaerobic Capacity (121-150% FTP)
            // Z7: Neuromuscular Power (> 150% FTP)
        ]
    }
    
    /// Calculate power zone distribution
    private func calculatePowerZoneDistribution(
        powerData: [Double],
        timeData: [Double],
        zoneThresholds: [Double]
    ) -> [PowerZoneData] {
        guard powerData.count == timeData.count, !powerData.isEmpty else { return [] }
        
        let totalZones = zoneThresholds.count + 1 // +1 for the highest zone
        var zoneTime: [TimeInterval] = Array(repeating: 0, count: totalZones)
        var zonePowerSum: [Double] = Array(repeating: 0, count: totalZones)
        var zoneDataPoints: [Int] = Array(repeating: 0, count: totalZones)
        
        // Calculate time in each zone
        for i in 0..<powerData.count {
            let power = powerData[i]
            let dt = i > 0 ? timeData[i] - timeData[i-1] : 1.0
            
            // Determine which zone this power value belongs to
            var zone = 0
            for (index, threshold) in zoneThresholds.enumerated() {
                if power <= threshold {
                    zone = index
                    break
                }
                zone = index + 1
            }
            
            zoneTime[zone] += dt
            zonePowerSum[zone] += power
            zoneDataPoints[zone] += 1
        }
        
        // Calculate total time
        let totalTime = timeData.last ?? 0
        
        // Create PowerZoneData objects
        var powerZones: [PowerZoneData] = []
        for zone in 0..<totalZones {
            let timeInZone = zoneTime[zone]
            let percentage = totalTime > 0 ? (timeInZone / totalTime) * 100.0 : 0
            let avgPower = zoneDataPoints[zone] > 0 ? zonePowerSum[zone] / Double(zoneDataPoints[zone]) : nil
            
            powerZones.append(PowerZoneData(
                zone: zone + 1, // Zones are 1-indexed
                timeInZone: timeInZone,
                percentageInZone: percentage,
                averagePowerInZone: avgPower
            ))
        }
        
        return powerZones
    }
    
    private func calculateAveragePower(powerData: [Double]) -> Double {
        guard !powerData.isEmpty else { return 0 }
        let sum = powerData.reduce(0, +)
        return sum / Double(powerData.count)
    }
    
    private func calculateNormalizedPower(powerData: [Double], timeData: [Double]) -> Double {
        guard powerData.count == timeData.count, powerData.count > 0 else { return 0 }
        
        // Step 1: Calculate 30-second rolling average
        let windowSize = 30
        var rollingAverages: [Double] = []
        
        for i in 0..<powerData.count {
            let startIdx = max(0, i - windowSize + 1)
            let window = Array(powerData[startIdx...i])
            let avg = window.reduce(0, +) / Double(window.count)
            rollingAverages.append(avg)
        }
        
        // Step 2: Raise each value to the 4th power
        let fourthPowers = rollingAverages.map { pow($0, 4) }
        
        // Step 3: Calculate average of 4th powers
        let avgFourthPower = fourthPowers.reduce(0, +) / Double(fourthPowers.count)
        
        // Step 4: Take 4th root
        let normalizedPower = pow(avgFourthPower, 0.25)
        
        return normalizedPower
    }
    
    private func estimateFTP(powerData: [Double], duration: TimeInterval) -> Double {
        // Simple estimation: use 95% of average power for rides > 20 minutes
        guard duration >= 1200 else { return 0 } // At least 20 minutes
        
        let avgPower = calculateAveragePower(powerData: powerData)
        return avgPower * 0.95
    }
    
    private func calculateIntensityFactor(normalizedPower: Double, ftp: Double) -> Double {
        guard ftp > 0 else { return 0 }
        return normalizedPower / ftp
    }
    
    private func calculateTSS(normalizedPower: Double, intensityFactor: Double, duration: TimeInterval, ftp: Double) -> Double {
        guard ftp > 0, duration > 0 else { return 0 }
        
        // TSS = (duration * NP * IF) / (FTP * 3600) * 100
        let durationHours = duration / 3600.0
        return (durationHours * normalizedPower * intensityFactor) / ftp * 100.0
    }
    
    private func calculateVariabilityIndex(normalizedPower: Double, averagePower: Double) -> Double {
        guard averagePower > 0 else { return 0 }
        return normalizedPower / averagePower
    }
    
    private func calculateEfficiencyFactor(normalizedPower: Double, averageHeartRate: Double) -> Double {
        guard averageHeartRate > 0 else { return 0 }
        return normalizedPower / averageHeartRate
    }
    
    private func calculateMaxAveragePower(powerData: [Double], timeData: [Double], duration: TimeInterval) -> Double? {
        guard powerData.count == timeData.count, powerData.count > 0 else { return nil }
        
        var maxAvg: Double = 0
        
        for i in 0..<powerData.count {
            // Find the end index for this duration
            let targetTime = timeData[i] + duration
            
            guard let endIdx = timeData.firstIndex(where: { $0 >= targetTime }) else {
                break
            }
            
            // Calculate average power for this window
            let window = Array(powerData[i...endIdx])
            let avg = window.reduce(0, +) / Double(window.count)
            
            maxAvg = max(maxAvg, avg)
        }
        
        return maxAvg > 0 ? maxAvg : nil
    }
}

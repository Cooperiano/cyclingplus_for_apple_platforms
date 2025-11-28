//
//  ActivityStreams.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

@Model
final class ActivityStreams {
    var activityId: String
    var timeData: [Double] // seconds from start
    var powerData: [Double?]? // watts
    var heartRateData: [Int?]? // bpm
    var cadenceData: [Int?]? // rpm
    var speedData: [Double?]? // m/s
    var elevationData: [Double?]? // meters
    var latLngData: [LatLng]? // GPS coordinates
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship back to activity
    var activity: Activity?
    
    init(
        activityId: String,
        timeData: [Double],
        powerData: [Double?]? = nil,
        heartRateData: [Int?]? = nil,
        cadenceData: [Int?]? = nil,
        speedData: [Double?]? = nil,
        elevationData: [Double?]? = nil,
        latLngData: [LatLng]? = nil
    ) {
        self.activityId = activityId
        self.timeData = timeData
        self.powerData = powerData
        self.heartRateData = heartRateData
        self.cadenceData = cadenceData
        self.speedData = speedData
        self.elevationData = elevationData
        self.latLngData = latLngData
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Stream Helpers

extension ActivityStreams {
    /// Returns paired time/value arrays for power samples, ignoring missing values.
    func powerTimeSeries() -> ([Double], [Double]) {
        return pairedDoubleStream(from: powerData)
    }
    
    /// Returns paired time/value arrays for speed samples, ignoring missing values.
    func speedTimeSeries() -> ([Double], [Double]) {
        return pairedDoubleStream(from: speedData)
    }
    
    /// Returns paired time/value arrays for elevation samples, ignoring missing values.
    func elevationTimeSeries() -> ([Double], [Double]) {
        return pairedDoubleStream(from: elevationData)
    }
    
    /// Returns paired time/value arrays for heart rate samples, ignoring missing values.
    func heartRateTimeSeries() -> ([Double], [Int]) {
        return pairedIntStream(from: heartRateData)
    }
    
    /// Returns paired time/value arrays for cadence samples, ignoring missing values.
    func cadenceTimeSeries() -> ([Double], [Int]) {
        return pairedIntStream(from: cadenceData)
    }
    
    /// Indicates whether the specified stream contains at least one valid data point.
    func hasData<T>(in stream: [T?]?) -> Bool {
        guard let stream else { return false }
        return stream.contains(where: { $0 != nil })
    }
    
    // MARK: - Private helpers
    
    private func pairedDoubleStream(from stream: [Double?]?) -> ([Double], [Double]) {
        guard let stream else { return ([], []) }
        
        var times: [Double] = []
        var values: [Double] = []
        
        for (time, value) in zip(timeData, stream) {
            times.append(time)
            values.append(value ?? 0)
        }
        
        return (times, values)
    }
    
    private func pairedIntStream(from stream: [Int?]?) -> ([Double], [Int]) {
        guard let stream else { return ([], []) }
        
        var times: [Double] = []
        var values: [Int] = []
        
        for (time, value) in zip(timeData, stream) {
            times.append(time)
            values.append(value ?? 0)
        }
        
        return (times, values)
    }
}

@Model
final class LatLng {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

//
//  Activity.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

@Model
final class Activity {
    var id: String
    var name: String
    var startDate: Date
    var distance: Double // meters
    var duration: TimeInterval // seconds
    var elevationGain: Double // meters
    var source: ActivitySource
    var stravaId: Int?
    var igpsportRideId: Int?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var streams: ActivityStreams?
    var powerAnalysis: PowerAnalysis?
    var heartRateAnalysis: HeartRateAnalysis?
    var aiAnalysis: AIAnalysis?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        startDate: Date,
        distance: Double,
        duration: TimeInterval,
        elevationGain: Double,
        source: ActivitySource,
        stravaId: Int? = nil,
        igpsportRideId: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.distance = distance
        self.duration = duration
        self.elevationGain = elevationGain
        self.source = source
        self.stravaId = stravaId
        self.igpsportRideId = igpsportRideId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum ActivitySource: String, Codable, CaseIterable {
    case strava = "strava"
    case igpsport = "igpsport"
    case gpx = "gpx"
    case tcx = "tcx"
    case fit = "fit"
    
    var displayName: String {
        switch self {
        case .strava: return "Strava"
        case .igpsport: return "iGPSport"
        case .gpx: return "GPX File"
        case .tcx: return "TCX File"
        case .fit: return "FIT File"
        }
    }
}
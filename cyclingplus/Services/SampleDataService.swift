//
//  SampleDataService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

@MainActor
class SampleDataService {
    static func createSampleActivity(in modelContext: ModelContext) throws {
        // Create a sample cycling activity
        let activity = Activity(
            name: "Morning Training Ride",
            startDate: Date().addingTimeInterval(-3600), // 1 hour ago
            distance: 25000, // 25km in meters
            duration: 3600, // 1 hour in seconds
            elevationGain: 350, // 350m elevation gain
            source: .strava,
            stravaId: 12345
        )
        
        // Create sample stream data
        let timeData = Array(stride(from: 0.0, through: 3600.0, by: 1.0)) // Every second for 1 hour
        let powerData = timeData.map { _ in Double.random(in: 150...300) } // Random power between 150-300W
        let heartRateData = timeData.map { _ in Int.random(in: 140...180) } // Random HR between 140-180 bpm
        let cadenceData = timeData.map { _ in Int.random(in: 80...100) } // Random cadence between 80-100 rpm
        let speedData = timeData.map { _ in Double.random(in: 8...12) } // Random speed between 8-12 m/s
        let elevationData = timeData.enumerated().map { index, _ in 
            100 + sin(Double(index) / 600) * 50 // Simulated elevation profile
        }
        
        let streams = ActivityStreams(
            activityId: activity.id,
            timeData: timeData,
            powerData: powerData.map { Optional($0) },
            heartRateData: heartRateData.map { Optional($0) },
            cadenceData: cadenceData.map { Optional($0) },
            speedData: speedData.map { Optional($0) },
            elevationData: elevationData.map { Optional($0) }
        )
        
        // Create sample power analysis
        let powerAnalysis = PowerAnalysis(
            activityId: activity.id,
            eFTP: 250,
            normalizedPower: 220,
            intensityFactor: 0.88,
            trainingStressScore: 65,
            variabilityIndex: 1.15,
            averagePower: 210,
            maxPower: 450
        )
        
        // Create sample heart rate analysis
        let heartRateAnalysis = HeartRateAnalysis(
            activityId: activity.id,
            hrTSS: 58,
            averageHR: 162,
            maxHR: 178
        )
        
        // Create sample AI analysis
        let aiAnalysis = AIAnalysis(
            activityId: activity.id,
            analysisText: "Great training session! Your power output was consistent throughout the ride, showing good endurance. The heart rate response indicates you were working in your aerobic zone for most of the session.",
            performanceInsights: [
                "Consistent power output throughout the ride",
                "Good aerobic base development",
                "Efficient pedaling cadence"
            ],
            trainingRecommendations: [
                "Consider adding some interval work to improve VO2 max",
                "Focus on maintaining this aerobic base",
                "Good recovery ride for tomorrow"
            ],
            recoveryAdvice: "Take an easy day tomorrow with light spinning or rest",
            performanceScore: 85
        )
        
        // Set up relationships
        activity.streams = streams
        activity.powerAnalysis = powerAnalysis
        activity.heartRateAnalysis = heartRateAnalysis
        activity.aiAnalysis = aiAnalysis
        
        streams.activity = activity
        powerAnalysis.activity = activity
        heartRateAnalysis.activity = activity
        aiAnalysis.activity = activity
        
        // Insert into context
        modelContext.insert(activity)
        modelContext.insert(streams)
        modelContext.insert(powerAnalysis)
        modelContext.insert(heartRateAnalysis)
        modelContext.insert(aiAnalysis)
        
        try modelContext.save()
    }
    
    static func createSampleUserProfile(in modelContext: ModelContext) throws {
        let preferences = UserPreferences(
            units: .metric,
            autoSync: true,
            syncInterval: 3600,
            aiAnalysisEnabled: true,
            aiProvider: "deepseek"
        )
        
        let profile = UserProfile(
            name: "Sample Cyclist",
            weight: 70,
            ftp: 250,
            maxHeartRate: 190,
            restingHeartRate: 50,
            lactateThresholdHR: 170,
            preferences: preferences
        )
        
        // Calculate zones based on FTP and HR
        profile.calculatePowerZones()
        profile.calculateHeartRateZones()
        
        modelContext.insert(preferences)
        modelContext.insert(profile)
        
        try modelContext.save()
    }
}

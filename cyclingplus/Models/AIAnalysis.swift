//
//  AIAnalysis.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

@Model
final class AIAnalysis {
    var activityId: String
    var analysisText: String
    var performanceInsights: [String]
    var trainingRecommendations: [String]
    var recoveryAdvice: String?
    var performanceScore: Double? // 0-100 overall performance rating
    var analysisDate: Date
    var aiProvider: String // "deepseek", "openai", etc.
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship back to activity
    var activity: Activity?
    
    init(
        activityId: String,
        analysisText: String,
        performanceInsights: [String] = [],
        trainingRecommendations: [String] = [],
        recoveryAdvice: String? = nil,
        performanceScore: Double? = nil,
        aiProvider: String = "deepseek"
    ) {
        self.activityId = activityId
        self.analysisText = analysisText
        self.performanceInsights = performanceInsights
        self.trainingRecommendations = trainingRecommendations
        self.recoveryAdvice = recoveryAdvice
        self.performanceScore = performanceScore
        self.analysisDate = Date()
        self.aiProvider = aiProvider
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
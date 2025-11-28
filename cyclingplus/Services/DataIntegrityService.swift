//
//  DataIntegrityService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData

/// Service for ensuring data integrity and performing data validation
class DataIntegrityService {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Data Validation
    
    /// Validate all activities in the database
    func validateAllActivities() async throws -> ValidationReport {
        let descriptor = FetchDescriptor<Activity>()
        let activities = try modelContext.fetch(descriptor)
        
        var report = ValidationReport()
        
        for activity in activities {
            let issues = validateActivity(activity)
            if !issues.isEmpty {
                report.activityIssues[activity.id] = issues
            }
        }
        
        return report
    }
    
    /// Validate a single activity
    func validateActivity(_ activity: Activity) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check basic fields
        if activity.name.isEmpty {
            issues.append(.emptyName(activityId: activity.id))
        }
        
        if activity.distance < 0 {
            issues.append(.invalidDistance(activityId: activity.id, value: activity.distance))
        }
        
        if activity.duration < 0 {
            issues.append(.invalidDuration(activityId: activity.id, value: activity.duration))
        }
        
        if activity.elevationGain < 0 {
            issues.append(.invalidElevation(activityId: activity.id, value: activity.elevationGain))
        }
        
        // Check stream data consistency
        if let streams = activity.streams {
            let streamIssues = validateStreams(streams)
            issues.append(contentsOf: streamIssues)
        }
        
        // Check for orphaned relationships
        if activity.streams != nil && activity.streams?.activity == nil {
            issues.append(.orphanedStreams(activityId: activity.id))
        }
        
        return issues
    }
    
    /// Validate stream data
    private func validateStreams(_ streams: ActivityStreams) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        let timeCount = streams.timeData.count
        
        // Check that all stream arrays have matching lengths
        if let powerData = streams.powerData, powerData.count != timeCount {
            issues.append(.streamLengthMismatch(activityId: streams.activityId, streamType: "power"))
        }
        
        if let hrData = streams.heartRateData, hrData.count != timeCount {
            issues.append(.streamLengthMismatch(activityId: streams.activityId, streamType: "heartRate"))
        }
        
        if let cadenceData = streams.cadenceData, cadenceData.count != timeCount {
            issues.append(.streamLengthMismatch(activityId: streams.activityId, streamType: "cadence"))
        }
        
        if let speedData = streams.speedData, speedData.count != timeCount {
            issues.append(.streamLengthMismatch(activityId: streams.activityId, streamType: "speed"))
        }
        
        if let elevationData = streams.elevationData, elevationData.count != timeCount {
            issues.append(.streamLengthMismatch(activityId: streams.activityId, streamType: "elevation"))
        }
        
        // Check for invalid values
        if let powerData = streams.powerData {
            if powerData.compactMap({ $0 }).contains(where: { $0 < 0 || $0 > 3000 }) {
                issues.append(.invalidStreamValues(activityId: streams.activityId, streamType: "power"))
            }
        }
        
        if let hrData = streams.heartRateData {
            if hrData.compactMap({ $0 }).contains(where: { $0 < 0 || $0 > 250 }) {
                issues.append(.invalidStreamValues(activityId: streams.activityId, streamType: "heartRate"))
            }
        }
        
        return issues
    }
    
    // MARK: - Data Repair
    
    /// Attempt to repair data issues
    func repairIssues(_ issues: [ValidationIssue]) async throws -> RepairReport {
        var report = RepairReport()
        
        for issue in issues {
            do {
                try await repairIssue(issue)
                report.repairedIssues.append(issue)
            } catch {
                report.failedRepairs[issue] = error
            }
        }
        
        try modelContext.save()
        return report
    }
    
    private func repairIssue(_ issue: ValidationIssue) async throws {
        switch issue {
        case .emptyName(let activityId):
            if let activity = try? fetchActivity(id: activityId) {
                activity.name = "Untitled Activity"
            }
            
        case .invalidDistance(let activityId, _):
            if let activity = try? fetchActivity(id: activityId) {
                activity.distance = 0
            }
            
        case .invalidDuration(let activityId, _):
            if let activity = try? fetchActivity(id: activityId) {
                activity.duration = 0
            }
            
        case .invalidElevation(let activityId, _):
            if let activity = try? fetchActivity(id: activityId) {
                activity.elevationGain = 0
            }
            
        case .orphanedStreams(let activityId):
            // Re-establish relationship
            if let activity = try? fetchActivity(id: activityId),
               let streams = activity.streams {
                streams.activity = activity
            }
            
        default:
            // Some issues cannot be automatically repaired
            throw DataIntegrityError.cannotRepair
        }
    }
    
    // MARK: - Data Cleanup
    
    /// Remove duplicate activities
    func removeDuplicates() async throws -> Int {
        let descriptor = FetchDescriptor<Activity>(sortBy: [SortDescriptor(\.startDate)])
        let activities = try modelContext.fetch(descriptor)
        
        var seen: Set<String> = []
        var duplicates: [Activity] = []
        
        for activity in activities {
            let key = "\(activity.source.rawValue)-\(activity.stravaId ?? 0)-\(activity.igpsportRideId ?? 0)-\(activity.startDate.timeIntervalSince1970)"
            
            if seen.contains(key) {
                duplicates.append(activity)
            } else {
                seen.insert(key)
            }
        }
        
        for duplicate in duplicates {
            modelContext.delete(duplicate)
        }
        
        try modelContext.save()
        return duplicates.count
    }
    
    /// Remove orphaned data
    func removeOrphanedData() async throws -> Int {
        var removedCount = 0
        
        // Find streams without activities
        let streamsDescriptor = FetchDescriptor<ActivityStreams>()
        let allStreams = try modelContext.fetch(streamsDescriptor)
        
        for streams in allStreams {
            if streams.activity == nil {
                modelContext.delete(streams)
                removedCount += 1
            }
        }
        
        try modelContext.save()
        return removedCount
    }
    
    // MARK: - Helper Methods
    
    private func fetchActivity(id: String) throws -> Activity? {
        let descriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Supporting Types

struct ValidationReport {
    var activityIssues: [String: [ValidationIssue]] = [:]
    
    var totalIssues: Int {
        activityIssues.values.reduce(0) { $0 + $1.count }
    }
    
    var hasIssues: Bool {
        !activityIssues.isEmpty
    }
}

struct RepairReport {
    var repairedIssues: [ValidationIssue] = []
    var failedRepairs: [ValidationIssue: Error] = [:]
    
    var successCount: Int {
        repairedIssues.count
    }
    
    var failureCount: Int {
        failedRepairs.count
    }
}

enum ValidationIssue: Hashable {
    case emptyName(activityId: String)
    case invalidDistance(activityId: String, value: Double)
    case invalidDuration(activityId: String, value: TimeInterval)
    case invalidElevation(activityId: String, value: Double)
    case streamLengthMismatch(activityId: String, streamType: String)
    case invalidStreamValues(activityId: String, streamType: String)
    case orphanedStreams(activityId: String)
    case orphanedAnalysis(activityId: String)
    
    var description: String {
        switch self {
        case .emptyName(let id):
            return "Activity \(id) has an empty name"
        case .invalidDistance(let id, let value):
            return "Activity \(id) has invalid distance: \(value)"
        case .invalidDuration(let id, let value):
            return "Activity \(id) has invalid duration: \(value)"
        case .invalidElevation(let id, let value):
            return "Activity \(id) has invalid elevation: \(value)"
        case .streamLengthMismatch(let id, let type):
            return "Activity \(id) has mismatched \(type) stream length"
        case .invalidStreamValues(let id, let type):
            return "Activity \(id) has invalid \(type) values"
        case .orphanedStreams(let id):
            return "Activity \(id) has orphaned streams"
        case .orphanedAnalysis(let id):
            return "Activity \(id) has orphaned analysis"
        }
    }
}

enum DataIntegrityError: LocalizedError {
    case cannotRepair
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .cannotRepair:
            return "This issue cannot be automatically repaired"
        case .validationFailed:
            return "Data validation failed"
        }
    }
}

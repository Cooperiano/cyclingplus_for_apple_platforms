//
//  DataRepository.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData
import Combine

@MainActor
class DataRepository: ObservableObject {
    @Published var isLoading = false
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Activity Management
    
    func saveActivity(_ activity: Activity) throws {
        modelContext.insert(activity)
        try modelContext.save()
    }
    
    func fetchActivities() throws -> [Activity] {
        let descriptor = FetchDescriptor<Activity>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchActivity(by id: String) throws -> Activity? {
        let predicate = #Predicate<Activity> { activity in
            activity.id == id
        }
        let descriptor = FetchDescriptor<Activity>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func fetchActivity(stravaId: Int) throws -> Activity? {
        let predicate = #Predicate<Activity> { activity in
            activity.stravaId == stravaId
        }
        let descriptor = FetchDescriptor<Activity>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func fetchActivity(igpsportRideId: Int) throws -> Activity? {
        let predicate = #Predicate<Activity> { activity in
            activity.igpsportRideId == igpsportRideId
        }
        let descriptor = FetchDescriptor<Activity>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func findDuplicateActivity(
        similarTo target: Activity,
        timeTolerance: TimeInterval = 10,
        distanceTolerance: Double = 20,
        durationTolerance: TimeInterval = 15
    ) throws -> Activity? {
        let startLowerBound = target.startDate.addingTimeInterval(-timeTolerance)
        let startUpperBound = target.startDate.addingTimeInterval(timeTolerance)

        let predicate = #Predicate<Activity> { candidate in
            candidate.startDate >= startLowerBound && candidate.startDate <= startUpperBound
        }

        let descriptor = FetchDescriptor<Activity>(predicate: predicate)
        let candidates = try modelContext.fetch(descriptor)

        return candidates.first(where: { candidate in
            guard candidate.id != target.id else { return false }
            let distanceDelta = abs(candidate.distance - target.distance)
            let durationDelta = abs(candidate.duration - target.duration)
            return distanceDelta <= distanceTolerance && durationDelta <= durationTolerance
        })
    }
    
    func updateActivity(_ activity: Activity) throws {
        activity.updatedAt = Date()
        try modelContext.save()
    }
    
    func deleteActivity(_ activity: Activity) throws {
        modelContext.delete(activity)
        try modelContext.save()
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile(_ profile: UserProfile) throws {
        modelContext.insert(profile)
        try modelContext.save()
    }
    
    func fetchUserProfile() throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try modelContext.fetch(descriptor).first
    }
    
    func updateUserProfile(_ profile: UserProfile) throws {
        profile.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - Analysis Data Management
    
    func saveActivityStreams(_ streams: ActivityStreams) throws {
        modelContext.insert(streams)
        try modelContext.save()
    }
    
    func savePowerAnalysis(_ analysis: PowerAnalysis) throws {
        modelContext.insert(analysis)
        try modelContext.save()
    }
    
    func saveHeartRateAnalysis(_ analysis: HeartRateAnalysis) throws {
        modelContext.insert(analysis)
        try modelContext.save()
    }
    
    func saveAIAnalysis(_ analysis: AIAnalysis) throws {
        modelContext.insert(analysis)
        try modelContext.save()
    }
    
    // MARK: - Search and Filter
    
    func searchActivities(query: String) throws -> [Activity] {
        let predicate = #Predicate<Activity> { activity in
            activity.name.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<Activity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchActivitiesBySource(_ source: ActivitySource) throws -> [Activity] {
        let predicate = #Predicate<Activity> { activity in
            activity.source == source
        }
        let descriptor = FetchDescriptor<Activity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchActivitiesInDateRange(from startDate: Date, to endDate: Date) throws -> [Activity] {
        let predicate = #Predicate<Activity> { activity in
            activity.startDate >= startDate && activity.startDate <= endDate
        }
        let descriptor = FetchDescriptor<Activity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Statistics
    
    func getTotalDistance() throws -> Double {
        let activities = try fetchActivities()
        return activities.reduce(0) { $0 + $1.distance }
    }
    
    func getTotalDuration() throws -> TimeInterval {
        let activities = try fetchActivities()
        return activities.reduce(0) { $0 + $1.duration }
    }
    
    func getActivityCount() throws -> Int {
        let descriptor = FetchDescriptor<Activity>()
        return try modelContext.fetchCount(descriptor)
    }
}

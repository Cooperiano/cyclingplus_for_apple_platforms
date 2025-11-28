//
//  StravaSyncService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData
import Combine

@MainActor
class StravaSyncService: ObservableObject {
    private let authManager: StravaAuthManager
    private let apiService: StravaAPIService
    private let dataRepository: DataRepository
    
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var syncStatus: String = ""
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    init(authManager: StravaAuthManager, dataRepository: DataRepository) {
        self.authManager = authManager
        self.apiService = StravaAPIService(authManager: authManager)
        self.dataRepository = dataRepository
        
        // Load last sync date from UserDefaults
        self.lastSyncDate = UserDefaults.standard.object(forKey: "strava_last_sync") as? Date
    }
    
    // MARK: - Public Sync Methods
    
    func syncAllActivities() async throws {
        guard authManager.isAuthenticated else {
            throw CyclingPlusError.authenticationFailed("Not authenticated with Strava")
        }
        
        isSyncing = true
        syncProgress = 0.0
        syncStatus = "Starting Strava sync..."
        syncError = nil
        
        defer {
            isSyncing = false
            syncProgress = 0.0
            syncStatus = ""
        }
        
        do {
            // Fetch activities with pagination
            var allActivities: [StravaActivity] = []
            var currentPage = 1
            let perPage = 30
            
            syncStatus = "Fetching activities from Strava..."
            
            while true {
                let activities = try await apiService.fetchActivities(page: currentPage, perPage: perPage)
                
                if activities.isEmpty {
                    break
                }
                
                allActivities.append(contentsOf: activities)
                syncProgress = min(0.3, Double(allActivities.count) / 200.0) // Estimate progress for activity fetching
                
                // Stop if we get fewer activities than requested (reached the end)
                if activities.count < perPage {
                    break
                }
                
                currentPage += 1
                
                // Limit to prevent excessive API calls
                if currentPage > 20 {
                    break
                }
                
                // Rate limiting
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
            
            syncStatus = "Processing \(allActivities.count) activities..."
            
            // Process activities and sync streams
            for (index, stravaActivity) in allActivities.enumerated() {
                try await syncSingleActivity(stravaActivity)
                
                syncProgress = 0.3 + (Double(index + 1) / Double(allActivities.count)) * 0.7
                syncStatus = "Synced \(index + 1) of \(allActivities.count) activities"
                
                // Rate limiting
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "strava_last_sync")
            
            syncStatus = "Sync completed successfully"
            
        } catch {
            syncError = error
            throw error
        }
    }
    
    func syncRecentActivities(days: Int = 7) async throws {
        guard authManager.isAuthenticated else {
            throw CyclingPlusError.authenticationFailed("Not authenticated with Strava")
        }
        
        isSyncing = true
        syncProgress = 0.0
        syncStatus = "Syncing recent activities..."
        syncError = nil
        
        defer {
            isSyncing = false
            syncProgress = 0.0
            syncStatus = ""
        }
        
        do {
            let activities = try await apiService.fetchActivities(page: 1, perPage: 50)
            
            // Filter activities from the last N days
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let recentActivities = activities.filter { activity in
                let activityDate = ISO8601DateFormatter().date(from: activity.startDate) ?? Date()
                return activityDate >= cutoffDate
            }
            
            syncStatus = "Processing \(recentActivities.count) recent activities..."
            
            for (index, stravaActivity) in recentActivities.enumerated() {
                try await syncSingleActivity(stravaActivity)
                
                syncProgress = Double(index + 1) / Double(recentActivities.count)
                syncStatus = "Synced \(index + 1) of \(recentActivities.count) activities"
                
                // Rate limiting
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "strava_last_sync")
            
        } catch {
            syncError = error
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func syncSingleActivity(_ stravaActivity: StravaActivity) async throws {
        // Check if activity already exists
        if let existingActivity = try dataRepository.fetchActivity(stravaId: stravaActivity.id) {
            // Update existing activity if needed
            updateExistingActivity(existingActivity, with: stravaActivity)
            return
        }
        
        // Convert Strava activity to local format
        let (activity, _) = apiService.convertStravaActivityToLocal(stravaActivity)
        
        // Save the activity
        try dataRepository.saveActivity(activity)
        
        // Fetch and save streams if the activity has power or heart rate data
        if stravaActivity.hasHeartrate || stravaActivity.averageWatts != nil {
            do {
                let stravaStreams = try await apiService.fetchActivityStreams(activityId: stravaActivity.id)
                let (_, activityStreams) = apiService.convertStravaActivityToLocal(stravaActivity, streams: stravaStreams)
                
                if let streams = activityStreams {
                    streams.activity = activity
                    try dataRepository.saveActivityStreams(streams)
                }
            } catch {
                // Log error but don't fail the entire sync
                print("Failed to fetch streams for activity \(stravaActivity.id): \(error)")
            }
        }
    }
    
    private func updateExistingActivity(_ existingActivity: Activity, with stravaActivity: StravaActivity) {
        // Update activity properties if they've changed
        existingActivity.name = stravaActivity.name
        existingActivity.distance = stravaActivity.distance
        existingActivity.duration = TimeInterval(stravaActivity.movingTime)
        existingActivity.elevationGain = stravaActivity.totalElevationGain
        existingActivity.updatedAt = Date()
        
        // Save changes
        do {
            try dataRepository.updateActivity(existingActivity)
        } catch {
            print("Failed to update activity \(existingActivity.id): \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    func cancelSync() {
        isSyncing = false
        syncStatus = "Sync cancelled"
    }
    
    func clearSyncHistory() {
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: "strava_last_sync")
    }
}

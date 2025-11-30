//
//  IGPSportSyncService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData
import Combine

@MainActor
class IGPSportSyncService: ObservableObject {
    private let authManager: IGPSportAuthManager
    private let apiService: IGPSportAPIService
    private let dataRepository: DataRepository
    
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var syncStatus: String = ""
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    init(authManager: IGPSportAuthManager, dataRepository: DataRepository) {
        self.authManager = authManager
        self.apiService = IGPSportAPIService(authManager: authManager)
        self.dataRepository = dataRepository
        
        // Load last sync date from UserDefaults
        self.lastSyncDate = UserDefaults.standard.object(forKey: "igpsport_last_sync") as? Date
    }
    
    // MARK: - Public Sync Methods
    
    func syncAllActivities(maxPages: Int = 50) async throws {
        guard authManager.isAuthenticated else {
            throw CyclingPlusError.authenticationFailed("Not authenticated with iGPSport")
        }
        
        isSyncing = true
        syncProgress = 0.0
        syncStatus = "Starting iGPSport sync..."
        syncError = nil
        
        defer {
            isSyncing = false
            syncProgress = 0.0
            syncStatus = ""
        }
        
        do {
            var allActivities: [IGPSportActivity] = []
            var currentPage = 1
            
            syncStatus = "Fetching activities from iGPSport..."
            
            while currentPage <= maxPages {
                let activities = try await apiService.fetchActivities(page: currentPage, pageSize: 20)
                
                if activities.isEmpty {
                    break
                }
                
                allActivities.append(contentsOf: activities)
                syncProgress = min(0.3, Double(allActivities.count) / 200.0)
                
                // Stop if we get fewer activities than requested
                if activities.count < 20 {
                    break
                }
                
                currentPage += 1
                
                // Rate limiting - be respectful to iGPSport API
                try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            }
            
            syncStatus = "Processing \(allActivities.count) activities..."
            
            // Process activities and download FIT files
            for (index, igpsActivity) in allActivities.enumerated() {
                try await syncSingleActivity(igpsActivity)
                
                syncProgress = 0.3 + (Double(index + 1) / Double(allActivities.count)) * 0.7
                syncStatus = "Synced \(index + 1) of \(allActivities.count) activities"
                
                // Rate limiting
                try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            }
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "igpsport_last_sync")
            
            syncStatus = "Sync completed successfully"
            
        } catch {
            syncError = error
            throw error
        }
    }
    
    func syncRecentActivities(days: Int = 7) async throws {
        guard authManager.isAuthenticated else {
            throw CyclingPlusError.authenticationFailed("Not authenticated with iGPSport")
        }
        
        isSyncing = true
        syncProgress = 0.0
        syncStatus = "Syncing recent iGPSport activities..."
        syncError = nil
        
        defer {
            isSyncing = false
            syncProgress = 0.0
            syncStatus = ""
        }
        
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let activities = try await apiService.syncActivitiesInDateRange(from: cutoffDate, to: Date(), maxPages: 10)
            
            syncStatus = "Processing \(activities.count) recent activities..."
            
            for (index, igpsActivity) in activities.enumerated() {
                try await syncSingleActivity(igpsActivity)
                
                syncProgress = Double(index + 1) / Double(activities.count)
                syncStatus = "Synced \(index + 1) of \(activities.count) activities"
                
                // Rate limiting
                try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            }
            
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "igpsport_last_sync")
            
        } catch {
            syncError = error
            throw error
        }
    }
    
    func syncActivityWithFITFile(rideId: Int) async throws -> (Activity, Data?) {
        // Fetch activity detail
        let activityDetail = try await apiService.fetchActivityDetail(rideId: rideId)
        
        // Convert to local activity
        let igpsActivity = IGPSportActivity(
            id: String(rideId),
            rideId: rideId,
            title: activityDetail.title,
            name: activityDetail.name,
            startTime: activityDetail.startTime,
            startTimeString: nil,
            distance: activityDetail.distance,
            duration: activityDetail.duration,
            elevationGain: activityDetail.elevationGain,
            averageSpeed: activityDetail.averageSpeed,
            maxSpeed: activityDetail.maxSpeed,
            averagePower: activityDetail.averagePower,
            maxPower: activityDetail.maxPower,
            averageHeartRate: activityDetail.averageHeartRate,
            maxHeartRate: activityDetail.maxHeartRate,
            averageCadence: activityDetail.averageCadence,
            maxCadence: activityDetail.maxCadence,
            calories: activityDetail.calories,
            fitOssPath: activityDetail.fitOssPath,
            fitUrl: activityDetail.fitUrl,
            fitPath: activityDetail.fitPath,
            fitDownloadUrl: activityDetail.fitDownloadUrl,
            fitOssUrl: activityDetail.fitOssUrl,
            fit: activityDetail.fit
        )
        
        let activity = apiService.convertIGPSportActivityToLocal(igpsActivity)
        
        // Download FIT file if available
        var fitData: Data? = nil
        if let fitURL = activityDetail.fitFileURL {
            do {
                fitData = try await apiService.downloadFITFile(from: fitURL)
            } catch {
                print("Failed to download FIT file for activity \(rideId): \(error)")
            }
        }
        
        return (activity, fitData)
    }
    
    // MARK: - Private Methods
    
    private func syncSingleActivity(_ igpsActivity: IGPSportActivity) async throws {
        // Check if activity already exists
        let activityId = "igpsport_\(igpsActivity.rideId)"
        if let existingActivity = try dataRepository.fetchActivity(igpsportRideId: igpsActivity.rideId) {
            // Update existing activity if needed
            updateExistingActivity(existingActivity, with: igpsActivity)
            return
        }
        
        // Convert to local activity
        let activity = apiService.convertIGPSportActivityToLocal(igpsActivity)
        activity.id = activityId // Use consistent ID format
        
        // Save the activity
        try dataRepository.saveActivity(activity)
        
        // Download and process FIT file if available
        if let fitURL = igpsActivity.fitFileURL {
            do {
                let fitData = try await apiService.downloadFITFile(from: fitURL)
                
                // Store FIT file data (we'll process it later when we implement FIT parsing)
                try saveFITFile(fitData, for: activity)
                
            } catch {
                // Log error but don't fail the entire sync
                print("Failed to download FIT file for activity \(igpsActivity.rideId): \(error)")
            }
        }
    }
    
    private func updateExistingActivity(_ existingActivity: Activity, with igpsActivity: IGPSportActivity) {
        // Update activity properties if they've changed
        existingActivity.name = igpsActivity.displayName
        if let distance = igpsActivity.distance {
            existingActivity.distance = distance
        }
        if let duration = igpsActivity.duration {
            existingActivity.duration = TimeInterval(duration)
        }
        if let elevation = igpsActivity.elevationGain {
            existingActivity.elevationGain = elevation
        }
        existingActivity.updatedAt = Date()
        
        // Save changes
        do {
            try dataRepository.updateActivity(existingActivity)
        } catch {
            print("Failed to update activity \(existingActivity.id): \(error)")
        }
    }
    
    private func saveFITFile(_ fitData: Data, for activity: Activity) throws {
        // Create a directory for FIT files if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fitDirectory = documentsPath.appendingPathComponent("FITFiles")
        
        if !FileManager.default.fileExists(atPath: fitDirectory.path) {
            try FileManager.default.createDirectory(at: fitDirectory, withIntermediateDirectories: true)
        }
        
        // Save FIT file with activity ID as filename
        let fitFileURL = fitDirectory.appendingPathComponent("\(activity.id).fit")
        try fitData.write(to: fitFileURL)
        
        print("Saved FIT file for activity \(activity.id) at \(fitFileURL.path)")
    }
    
    // MARK: - Utility Methods
    
    func cancelSync() {
        isSyncing = false
        syncStatus = "Sync cancelled"
    }
    
    func clearSyncHistory() {
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: "igpsport_last_sync")
    }
    
    func getFITFileURL(for activity: Activity) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fitFileURL = documentsPath.appendingPathComponent("FITFiles/\(activity.id).fit")
        
        return FileManager.default.fileExists(atPath: fitFileURL.path) ? fitFileURL : nil
    }
}

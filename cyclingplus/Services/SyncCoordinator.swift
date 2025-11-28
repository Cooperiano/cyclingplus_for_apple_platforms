//
//  SyncCoordinator.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftData
import Combine

@MainActor
class SyncCoordinator: ObservableObject {
    private let stravaAuthManager: StravaAuthManager
    private let igpsportAuthManager: IGPSportAuthManager
    private let dataRepository: DataRepository
    
    private var stravaSyncService: StravaSyncService?
    private var igpsportSyncService: IGPSportSyncService?
    
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var syncStatus: String = ""
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [Error] = []
    
    // Background sync settings
    @Published var autoSyncEnabled = true
    @Published var syncInterval: TimeInterval = 3600 // 1 hour
    
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(stravaAuthManager: StravaAuthManager, igpsportAuthManager: IGPSportAuthManager, dataRepository: DataRepository) {
        self.stravaAuthManager = stravaAuthManager
        self.igpsportAuthManager = igpsportAuthManager
        self.dataRepository = dataRepository
        
        // Initialize sync services
        self.stravaSyncService = StravaSyncService(authManager: stravaAuthManager, dataRepository: dataRepository)
        self.igpsportSyncService = IGPSportSyncService(authManager: igpsportAuthManager, dataRepository: dataRepository)
        
        // Load settings
        loadSettings()
        
        // Set up observers
        setupObservers()
        
        // Start background sync if enabled
        if autoSyncEnabled {
            startBackgroundSync()
        }
    }
    
    // MARK: - Public Sync Methods
    
    func syncAllServices() async throws {
        guard !isSyncing else { return }
        
        // Check if any services are actually connected
        guard connectedServicesCount > 0 else {
            print("No services connected, skipping sync")
            return
        }
        
        isSyncing = true
        syncProgress = 0.0
        syncStatus = "Starting sync..."
        syncErrors.removeAll()
        
        defer {
            isSyncing = false
            syncProgress = 1.0
            syncStatus = "Sync completed"
        }
        
        var completedServices = 0
        let totalServices = connectedServicesCount
        
        // Sync Strava if connected
        if stravaAuthManager.isAuthenticated, let stravaSyncService = stravaSyncService {
            do {
                syncStatus = "Syncing Strava..."
                try await stravaSyncService.syncRecentActivities()
                completedServices += 1
                syncProgress = Double(completedServices) / Double(totalServices)
            } catch {
                syncErrors.append(error)
                print("Strava sync failed: \(error)")
            }
        }
        
        // Sync iGPSport if connected
        if igpsportAuthManager.isAuthenticated, let igpsportSyncService = igpsportSyncService {
            do {
                syncStatus = "Syncing iGPSport..."
                try await igpsportSyncService.syncRecentActivities()
                completedServices += 1
                syncProgress = Double(completedServices) / Double(totalServices)
            } catch {
                syncErrors.append(error)
                print("iGPSport sync failed: \(error)")
            }
        }
        
        // Update last sync date
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "last_sync_date")
        
        // Throw error if all syncs failed
        if syncErrors.count == totalServices {
            throw CyclingPlusError.analysisError("All sync operations failed")
        }
    }
    
    func syncStrava() async throws {
        guard stravaAuthManager.isAuthenticated else {
            print("Strava not authenticated, skipping sync")
            return
        }
        
        guard let stravaSyncService = stravaSyncService else {
            throw CyclingPlusError.authenticationFailed("Strava sync service not initialized")
        }
        
        try await stravaSyncService.syncRecentActivities()
    }
    
    func syncIGPSport() async throws {
        guard igpsportAuthManager.isAuthenticated else {
            print("iGPSport not authenticated, skipping sync")
            return
        }
        
        guard let igpsportSyncService = igpsportSyncService else {
            throw CyclingPlusError.authenticationFailed("iGPSport sync service not initialized")
        }
        
        try await igpsportSyncService.syncRecentActivities()
    }
    
    func fullSyncAllServices() async throws {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncProgress = 0.0
        syncStatus = "Starting full sync..."
        syncErrors.removeAll()
        
        defer {
            isSyncing = false
            syncProgress = 1.0
            syncStatus = "Full sync completed"
        }
        
        var completedServices = 0
        let totalServices = connectedServicesCount
        
        // Full sync Strava if connected
        if stravaAuthManager.isAuthenticated, let stravaSyncService = stravaSyncService {
            do {
                syncStatus = "Full sync: Strava..."
                try await stravaSyncService.syncAllActivities()
                completedServices += 1
                syncProgress = Double(completedServices) / Double(totalServices)
            } catch {
                syncErrors.append(error)
                print("Strava full sync failed: \(error)")
            }
        }
        
        // Full sync iGPSport if connected
        if igpsportAuthManager.isAuthenticated, let igpsportSyncService = igpsportSyncService {
            do {
                syncStatus = "Full sync: iGPSport..."
                try await igpsportSyncService.syncAllActivities()
                completedServices += 1
                syncProgress = Double(completedServices) / Double(totalServices)
            } catch {
                syncErrors.append(error)
                print("iGPSport full sync failed: \(error)")
            }
        }
        
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "last_sync_date")
    }
    
    // MARK: - Background Sync
    
    func startBackgroundSync() {
        stopBackgroundSync()
        
        guard autoSyncEnabled && connectedServicesCount > 0 else { return }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isSyncing else { return }
                
                do {
                    try await self.syncAllServices()
                } catch {
                    print("Background sync failed: \(error)")
                }
            }
        }
        
        print("Background sync started with interval: \(syncInterval) seconds")
    }
    
    func stopBackgroundSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("Background sync stopped")
    }
    
    func updateSyncSettings(autoSync: Bool, interval: TimeInterval) {
        autoSyncEnabled = autoSync
        syncInterval = interval
        
        saveSettings()
        
        if autoSyncEnabled {
            startBackgroundSync()
        } else {
            stopBackgroundSync()
        }
    }
    
    // MARK: - Private Methods
    
    private var connectedServicesCount: Int {
        var count = 0
        if stravaAuthManager.isAuthenticated { count += 1 }
        if igpsportAuthManager.isAuthenticated { count += 1 }
        return count
    }
    
    private func setupObservers() {
        // Observe authentication state changes
        stravaAuthManager.$isAuthenticated
            .combineLatest(igpsportAuthManager.$isAuthenticated)
            .sink { [weak self] _, _ in
                self?.handleAuthenticationChange()
            }
            .store(in: &cancellables)
        
        // Observe sync service progress
        stravaSyncService?.$syncProgress
            .sink { [weak self] progress in
                if self?.stravaSyncService?.isSyncing == true {
                    self?.syncProgress = progress * 0.5 // Strava takes 50% of total progress
                }
            }
            .store(in: &cancellables)
        
        igpsportSyncService?.$syncProgress
            .sink { [weak self] progress in
                if self?.igpsportSyncService?.isSyncing == true {
                    let baseProgress = self?.stravaAuthManager.isAuthenticated == true ? 0.5 : 0.0
                    self?.syncProgress = baseProgress + (progress * 0.5)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthenticationChange() {
        if autoSyncEnabled {
            if connectedServicesCount > 0 {
                startBackgroundSync()
            } else {
                stopBackgroundSync()
            }
        }
    }
    
    private func loadSettings() {
        autoSyncEnabled = UserDefaults.standard.object(forKey: "auto_sync_enabled") as? Bool ?? true
        syncInterval = UserDefaults.standard.object(forKey: "sync_interval") as? TimeInterval ?? 3600
        lastSyncDate = UserDefaults.standard.object(forKey: "last_sync_date") as? Date
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(autoSyncEnabled, forKey: "auto_sync_enabled")
        UserDefaults.standard.set(syncInterval, forKey: "sync_interval")
    }
    
    // MARK: - Utility Methods
    
    func cancelSync() {
        stravaSyncService?.cancelSync()
        igpsportSyncService?.cancelSync()
        isSyncing = false
        syncStatus = "Sync cancelled"
    }
    
    func clearSyncHistory() {
        stravaSyncService?.clearSyncHistory()
        igpsportSyncService?.clearSyncHistory()
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: "last_sync_date")
    }
    
    func getSyncStatistics() -> SyncStatistics {
        return SyncStatistics(
            lastSyncDate: lastSyncDate,
            connectedServices: connectedServicesCount,
            autoSyncEnabled: autoSyncEnabled,
            syncInterval: syncInterval,
            recentErrors: syncErrors
        )
    }
}

struct SyncStatistics {
    let lastSyncDate: Date?
    let connectedServices: Int
    let autoSyncEnabled: Bool
    let syncInterval: TimeInterval
    let recentErrors: [Error]
}
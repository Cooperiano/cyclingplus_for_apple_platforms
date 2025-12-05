//
//  cyclingplusApp.swift
//  cyclingplus
//
//  Created by Julian Cooper on 2025/11/5.
//

import SwiftUI
import SwiftData

@main
struct cyclingplusApp: App {
    @StateObject private var stravaAuthManager = StravaAuthManager()
    @StateObject private var igpsportAuthManager = IGPSportAuthManager()
    @StateObject private var networkPermissionService = NetworkPermissionService()
    @StateObject private var urlSchemeHandler: URLSchemeHandler
    @StateObject private var syncCoordinator: SyncCoordinator
    @StateObject private var languageManager = LanguageManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Legacy model (can be removed later)
            Item.self,
            // Core cycling data models
            Activity.self,
            ActivityStreams.self,
            PowerAnalysis.self,
            HeartRateAnalysis.self,
            AIAnalysis.self,
            UserProfile.self,
            UserPreferences.self,
            // Supporting models
            PowerZoneData.self,
            MMPPoint.self,
            HRZoneData.self,
            LatLng.self
        ])
        
        // Use explicit URL for database to ensure clean creation
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = appSupportURL.appendingPathComponent("cyclingplus.store")
        
        let modelConfiguration = ModelConfiguration(
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully at: \(storeURL.path)")
            return container
        } catch {
            print("❌ Failed to create ModelContainer: \(error)")
            print("📍 Attempted location: \(storeURL.path)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        let stravaAuthManager = StravaAuthManager()
        let igpsportAuthManager = IGPSportAuthManager()
        let networkPermissionService = NetworkPermissionService()
        
        self._stravaAuthManager = StateObject(wrappedValue: stravaAuthManager)
        self._igpsportAuthManager = StateObject(wrappedValue: igpsportAuthManager)
        self._networkPermissionService = StateObject(wrappedValue: networkPermissionService)
        self._urlSchemeHandler = StateObject(wrappedValue: URLSchemeHandler(stravaAuthManager: stravaAuthManager))
        
        // Use the shared model container for the sync coordinator
        let mainRepository = DataRepository(modelContext: sharedModelContainer.mainContext)
        self._syncCoordinator = StateObject(wrappedValue: SyncCoordinator(
            stravaAuthManager: stravaAuthManager,
            igpsportAuthManager: igpsportAuthManager,
            dataRepository: mainRepository
        ))
        
        // Verify network permissions on startup
        Task {
            await networkPermissionService.verifyNetworkPermissions()
        }
    }

    var body: some Scene {
        #if os(macOS)
        // macOS version with menu commands and settings window
        WindowGroup {
            ContentView()
                .environmentObject(stravaAuthManager)
                .environmentObject(igpsportAuthManager)
                .environmentObject(networkPermissionService)
                .environmentObject(syncCoordinator)
                .environmentObject(languageManager)
                .onOpenURL { url in
                    Task {
                        await urlSchemeHandler.handleURL(url)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            // File menu commands
            CommandGroup(replacing: .newItem) {
                Button("Import Activity...") {
                    // TODO: Trigger file import
                }
                .keyboardShortcut("i", modifiers: .command)
            }
            
            // View menu commands
            CommandMenu("View") {
                Button("Activities") {
                    // TODO: Navigate to activities
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Settings") {
                    // TODO: Navigate to settings
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Divider()
                
                Button("Refresh") {
                    Task {
                        try? await syncCoordinator.syncAllServices()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            
            // Sync menu commands
            CommandMenu("Sync") {
                Button("Sync All") {
                    Task {
                        try? await syncCoordinator.syncAllServices()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button("Sync Strava") {
                    Task {
                        try? await syncCoordinator.syncStrava()
                    }
                }
                .disabled(!stravaAuthManager.isAuthenticated)
                
                Button("Sync iGPSport") {
                    Task {
                        try? await syncCoordinator.syncIGPSport()
                    }
                }
                .disabled(!igpsportAuthManager.isAuthenticated)
            }
            
            // Help menu additions
            CommandGroup(after: .help) {
                Button("CyclingPlus Help") {
                    if let url = URL(string: "https://github.com/yourusername/cyclingplus") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
        
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(stravaAuthManager)
                .environmentObject(igpsportAuthManager)
                .environmentObject(networkPermissionService)
                .environmentObject(syncCoordinator)
                .environmentObject(languageManager)
                .frame(minWidth: 800, idealWidth: 900, maxWidth: 1200, minHeight: 600, idealHeight: 700, maxHeight: 1000)
        }
        #else
        // iOS version - simpler without menu commands
        WindowGroup {
            ContentView()
                .environmentObject(stravaAuthManager)
                .environmentObject(igpsportAuthManager)
                .environmentObject(networkPermissionService)
                .environmentObject(syncCoordinator)
                .environmentObject(languageManager)
                .onOpenURL { url in
                    Task {
                        await urlSchemeHandler.handleURL(url)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
}

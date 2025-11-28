//
//  SyncMenuButton.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData

struct SyncMenuButton: View {
    @EnvironmentObject private var stravaAuthManager: StravaAuthManager
    @EnvironmentObject private var igpsportAuthManager: IGPSportAuthManager
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    
    @State private var showingFileImport = false
    
    var body: some View {
        Menu {
            if hasConnectedServices {
                syncSection
                Divider()
            }
            
            importSection
            
            if hasConnectedServices {
                Divider()
                settingsSection
            }
        } label: {
            if syncCoordinator.isSyncing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .font(.caption)
                }
            } else {
                Label("Add Activity", systemImage: "plus")
            }
        }
        .disabled(syncCoordinator.isSyncing)
        .sheet(isPresented: $showingFileImport) {
            FileImportView()
        }
    }
    
    private var hasConnectedServices: Bool {
        stravaAuthManager.isAuthenticated || igpsportAuthManager.isAuthenticated
    }
    
    @ViewBuilder
    private var syncSection: some View {
        Button("Sync All Services", systemImage: "arrow.clockwise") {
            Task {
                try? await syncCoordinator.syncAllServices()
            }
        }
        .disabled(!hasConnectedServices)
        
        if stravaAuthManager.isAuthenticated {
            Button("Sync Strava", systemImage: "arrow.clockwise") {
                Task {
                    try? await syncCoordinator.syncStrava()
                }
            }
        }
        
        if igpsportAuthManager.isAuthenticated {
            Button("Sync iGPSport", systemImage: "arrow.clockwise") {
                Task {
                    try? await syncCoordinator.syncIGPSport()
                }
            }
        }
    }
    
    @ViewBuilder
    private var importSection: some View {
        Button("Import Files", systemImage: "doc.badge.plus") {
            showingFileImport = true
        }
    }
    
    @ViewBuilder
    private var settingsSection: some View {
        Button("Full Sync", systemImage: "arrow.clockwise.circle") {
            Task {
                try? await syncCoordinator.fullSyncAllServices()
            }
        }
        
        if syncCoordinator.isSyncing {
            Button("Cancel Sync", systemImage: "xmark.circle") {
                syncCoordinator.cancelSync()
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Activity.self)
    let repository = DataRepository(modelContext: container.mainContext)
    
    SyncMenuButton()
        .environmentObject(StravaAuthManager())
        .environmentObject(IGPSportAuthManager())
        .environmentObject(SyncCoordinator(
            stravaAuthManager: StravaAuthManager(),
            igpsportAuthManager: IGPSportAuthManager(),
            dataRepository: repository
        ))
}
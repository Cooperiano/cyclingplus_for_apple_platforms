//
//  ToolbarSyncButtons.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/8.
//

import SwiftUI
import SwiftData

struct ToolbarSyncButtons: View {
    @EnvironmentObject private var stravaAuthManager: StravaAuthManager
    @EnvironmentObject private var igpsportAuthManager: IGPSportAuthManager
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    
    var body: some View {
        HStack(spacing: 8) {
            // Strava sync button
            if stravaAuthManager.isAuthenticated {
                Button(action: {
                    Task {
                        try? await syncCoordinator.syncStrava()
                    }
                }) {
                    HStack(spacing: 4) {
                        if syncCoordinator.isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Strava")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(syncCoordinator.isSyncing)
                .help("Sync Strava activities")
            }
            
            // iGPSport sync button
            if igpsportAuthManager.isAuthenticated {
                Button(action: {
                    Task {
                        try? await syncCoordinator.syncIGPSport()
                    }
                }) {
                    HStack(spacing: 4) {
                        if syncCoordinator.isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("iGPSport")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(syncCoordinator.isSyncing)
                .help("Sync iGPSport activities")
            }
            
            // Sync all button (only show if multiple services connected)
            if stravaAuthManager.isAuthenticated && igpsportAuthManager.isAuthenticated {
                Button(action: {
                    Task {
                        try? await syncCoordinator.syncAllServices()
                    }
                }) {
                    HStack(spacing: 4) {
                        if syncCoordinator.isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Sync All")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(syncCoordinator.isSyncing)
                .help("Sync all connected services")
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Activity.self)
    let repository = DataRepository(modelContext: container.mainContext)
    let stravaAuth = StravaAuthManager()
    let igpsportAuth = IGPSportAuthManager()
    
    ToolbarSyncButtons()
        .environmentObject(stravaAuth)
        .environmentObject(igpsportAuth)
        .environmentObject(SyncCoordinator(
            stravaAuthManager: stravaAuth,
            igpsportAuthManager: igpsportAuth,
            dataRepository: repository
        ))
        .padding()
}

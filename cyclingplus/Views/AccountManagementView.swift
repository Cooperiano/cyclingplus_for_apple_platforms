//
//  AccountManagementView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData

struct AccountManagementView: View {
    @EnvironmentObject private var stravaAuthManager: StravaAuthManager
    @EnvironmentObject private var igpsportAuthManager: IGPSportAuthManager
    
    var body: some View {
        List {
            Section {
                Text("Manage your connected data sources and sync settings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section("Connected Services") {
                ServiceConnectionRow(
                    serviceName: "Strava",
                    icon: "link.circle.fill",
                    iconColor: .orange,
                    isConnected: stravaAuthManager.isAuthenticated,
                    connectionInfo: stravaConnectionInfo,
                    destination: AnyView(StravaAuthView(authManager: stravaAuthManager))
                )
                
                ServiceConnectionRow(
                    serviceName: "iGPSport",
                    icon: "link.circle.fill",
                    iconColor: .blue,
                    isConnected: igpsportAuthManager.isAuthenticated,
                    connectionInfo: igpsportConnectionInfo,
                    destination: AnyView(IGPSportAuthView(authManager: igpsportAuthManager))
                )
            }
            
            if hasAnyConnection {
                Section("Sync Status") {
                    SyncStatusDetailView()
                }
                
                Section("Quick Actions") {
                    QuickActionsView()
                }
            }
        }
        .navigationTitle("Account Management")
    }
    
    private var stravaConnectionInfo: String {
        if stravaAuthManager.isAuthenticated {
            return stravaAuthManager.currentAthlete?.displayName ?? "Connected"
        } else {
            return "Not connected"
        }
    }
    
    private var igpsportConnectionInfo: String {
        if igpsportAuthManager.isAuthenticated {
            return igpsportAuthManager.currentUsername ?? "Connected"
        } else {
            return "Not connected"
        }
    }
    
    private var hasAnyConnection: Bool {
        stravaAuthManager.isAuthenticated || igpsportAuthManager.isAuthenticated
    }
}

struct ServiceConnectionRow: View {
    let serviceName: String
    let icon: String
    let iconColor: Color
    let isConnected: Bool
    let connectionInfo: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(serviceName)
                        .font(.headline)
                    
                    Text(connectionInfo)
                        .font(.caption)
                        .foregroundColor(isConnected ? .green : .secondary)
                }
                
                Spacer()
                
                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct SyncStatusDetailView: View {
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    @EnvironmentObject private var stravaAuthManager: StravaAuthManager
    @EnvironmentObject private var igpsportAuthManager: IGPSportAuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: syncCoordinator.isSyncing ? "arrow.clockwise" : "arrow.clockwise.circle")
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(syncCoordinator.isSyncing ? 360 : 0))
                    .animation(syncCoordinator.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: syncCoordinator.isSyncing)
                
                Text("Sync Status")
                    .font(.headline)
                
                Spacer()
                
                if let lastSync = syncCoordinator.lastSyncDate {
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if syncCoordinator.isSyncing {
                VStack(alignment: .leading, spacing: 4) {
                    Text(syncCoordinator.syncStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: syncCoordinator.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
            
            if stravaAuthManager.isAuthenticated {
                SyncServiceStatus(serviceName: "Strava", isConnected: true)
            }
            
            if igpsportAuthManager.isAuthenticated {
                SyncServiceStatus(serviceName: "iGPSport", isConnected: true)
            }
            
            if !syncCoordinator.syncErrors.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Errors:")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    ForEach(Array(syncCoordinator.syncErrors.prefix(3).enumerated()), id: \.offset) { _, error in
                        Text(error.localizedDescription)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct SyncServiceStatus: View {
    let serviceName: String
    let isConnected: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(serviceName)
                .font(.caption)
            
            Spacer()
            
            Text(isConnected ? "Ready" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.leading, 16)
    }
}

struct QuickActionsView: View {
    @EnvironmentObject private var stravaAuthManager: StravaAuthManager
    @EnvironmentObject private var igpsportAuthManager: IGPSportAuthManager
    @EnvironmentObject private var syncCoordinator: SyncCoordinator
    
    var body: some View {
        VStack(spacing: 12) {
            if stravaAuthManager.isAuthenticated || igpsportAuthManager.isAuthenticated {
                Button(action: syncAllServices) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync All Services")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(syncCoordinator.isSyncing)
                
                Button(action: fullSyncAllServices) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Full Sync All")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(syncCoordinator.isSyncing)
            }
            
            if stravaAuthManager.isAuthenticated && igpsportAuthManager.isAuthenticated {
                Button(action: disconnectAllServices) {
                    HStack {
                        Image(systemName: "link.badge.minus")
                        Text("Disconnect All")
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
    }
    
    private func syncAllServices() {
        Task {
            try? await syncCoordinator.syncAllServices()
        }
    }
    
    private func fullSyncAllServices() {
        Task {
            try? await syncCoordinator.fullSyncAllServices()
        }
    }
    
    private func disconnectAllServices() {
        stravaAuthManager.logout()
        igpsportAuthManager.logout()
    }
}

#Preview {
    let container = try! ModelContainer(for: Activity.self)
    let repository = DataRepository(modelContext: container.mainContext)
    
    NavigationView {
        AccountManagementView()
            .environmentObject(StravaAuthManager())
            .environmentObject(IGPSportAuthManager())
            .environmentObject(SyncCoordinator(
                stravaAuthManager: StravaAuthManager(),
                igpsportAuthManager: IGPSportAuthManager(),
                dataRepository: repository
            ))
    }
    .modelContainer(container)
}
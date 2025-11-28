//
//  ConnectionStatusWidget.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct ConnectionStatusWidget: View {
    @EnvironmentObject private var stravaAuthManager: StravaAuthManager
    @EnvironmentObject private var igpsportAuthManager: IGPSportAuthManager
    
    var body: some View {
        if !hasAnyConnection {
            connectionPrompt
        } else {
            connectedServicesStatus
        }
    }
    
    private var hasAnyConnection: Bool {
        stravaAuthManager.isAuthenticated || igpsportAuthManager.isAuthenticated
    }
    
    private var connectionPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.circle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Connect Your Data Sources")
                .font(.headline)
            
            Text("Connect to Strava or iGPSport to start analyzing your cycling data")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: AccountManagementView()) {
                Text("Connect Services")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        #if os(macOS)
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .cornerRadius(12)
    }
    
    private var connectedServicesStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Connected Services")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: AccountManagementView()) {
                    Text("Manage")
                        .font(.caption)
                }
            }
            
            HStack(spacing: 16) {
                if stravaAuthManager.isAuthenticated {
                    ServiceBadge(name: "Strava", color: .orange)
                }
                
                if igpsportAuthManager.isAuthenticated {
                    ServiceBadge(name: "iGPSport", color: .blue)
                }
            }
        }
        .padding()
        #if os(macOS)
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .cornerRadius(12)
    }
}

struct ServiceBadge: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        VStack {
            ConnectionStatusWidget()
                .environmentObject(StravaAuthManager())
                .environmentObject(IGPSportAuthManager())
        }
        .padding()
    }
}
//
//  NetworkDiagnosticsView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/8.
//

import SwiftUI

struct NetworkDiagnosticsView: View {
    @EnvironmentObject private var networkPermissionService: NetworkPermissionService
    @State private var isTesting = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        Form {
            Section("Network Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    statusBadge
                }
                
                if let result = networkPermissionService.lastTestResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Last Test")
                                .font(.headline)
                            Spacer()
                            Text(result.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.success ? .green : .red)
                            Text(result.message)
                                .font(.subheadline)
                        }
                        
                        if let details = result.details {
                            Text(details)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 24)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Actions") {
                Button(action: testConnection) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Test Network Connection")
                    }
                }
                .disabled(isTesting)
                
                Button(action: verifyPermissions) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "checkmark.shield")
                        }
                        Text("Verify Permissions")
                    }
                }
                .disabled(isTesting)
            }
            
            Section("Information") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "checkmark.circle",
                        title: "Network Available",
                        description: "App can connect to the internet normally"
                    )
                    
                    InfoRow(
                        icon: "exclamationmark.triangle",
                        title: "Network Restricted",
                        description: "App is missing network client entitlements or permissions"
                    )
                    
                    InfoRow(
                        icon: "wifi.slash",
                        title: "Network Unavailable",
                        description: "No internet connection or proxy configuration issue"
                    )
                }
                .padding(.vertical, 4)
            }
            
            Section("Troubleshooting") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If network is restricted:")
                        .font(.headline)
                    
                    Text("• Ensure the app has network client entitlements configured")
                        .font(.caption)
                    Text("• Check that com.apple.security.network.client is present in entitlements")
                        .font(.caption)
                    Text("• Rebuild the app if entitlements were recently added")
                        .font(.caption)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("If using a proxy:")
                        .font(.headline)
                    
                    Text("• Configure proxy in System Settings → Network")
                        .font(.caption)
                    Text("• Verify proxy server is reachable")
                        .font(.caption)
                    Text("• Check proxy authentication credentials")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Network Diagnostics")
        .alert("Connection Successful", isPresented: $showSuccessMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Network connection is working properly. You can connect to Strava and other services.")
        }
    }
    
    private var statusBadge: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.subheadline)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusText: String {
        switch networkPermissionService.networkStatus {
        case .available:
            return "Available"
        case .restricted:
            return "Restricted"
        case .unavailable:
            return "Unavailable"
        case .unknown:
            return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch networkPermissionService.networkStatus {
        case .available:
            return .green
        case .restricted:
            return .red
        case .unavailable:
            return .orange
        case .unknown:
            return .secondary
        }
    }
    
    private func testConnection() {
        isTesting = true
        Task {
            let result = await networkPermissionService.testNetworkConnection()
            isTesting = false
            
            if result.success {
                showSuccessMessage = true
            }
        }
    }
    
    private func verifyPermissions() {
        isTesting = true
        Task {
            await networkPermissionService.verifyNetworkPermissions()
            isTesting = false
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        NetworkDiagnosticsView()
            .environmentObject(NetworkPermissionService())
    }
}

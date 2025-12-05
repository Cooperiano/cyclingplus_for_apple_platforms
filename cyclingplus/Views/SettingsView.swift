//
//  SettingsView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var stravaAuthManager: StravaAuthManager
    @EnvironmentObject private var igpsportAuthManager: IGPSportAuthManager
    @EnvironmentObject private var networkPermissionService: NetworkPermissionService
    @EnvironmentObject private var languageManager: LanguageManager
    
    private var connectionStatusIndicator: some View {
        HStack(spacing: 4) {
            if stravaAuthManager.isAuthenticated {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
            }
            if igpsportAuthManager.isAuthenticated {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
            if !stravaAuthManager.isAuthenticated && !igpsportAuthManager.isAuthenticated {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var networkStatusText: String {
        switch networkPermissionService.networkStatus {
        case .available:
            return "Network available"
        case .restricted:
            return "Network restricted"
        case .unavailable:
            return "Network unavailable"
        case .unknown:
            return "Status unknown"
        }
    }
    
    private var networkStatusColor: Color {
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
    
    private var networkStatusIcon: some View {
        Group {
            switch networkPermissionService.networkStatus {
            case .available:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .restricted:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            case .unavailable:
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
            case .unknown:
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    NavigationLink(destination: AccountManagementView()) {
                        HStack {
                            Image(systemName: "person.2.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Account Management")
                                    .font(.headline)
                                Text("Manage connected services")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            connectionStatusIndicator
                        }
                    }
                }
                
                Section("Data Sources") {
                    NavigationLink(destination: StravaAuthView(authManager: stravaAuthManager)) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Strava")
                                    .font(.headline)
                                if stravaAuthManager.isAuthenticated {
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Not connected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if stravaAuthManager.isAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    NavigationLink(destination: IGPSportAuthView(authManager: igpsportAuthManager)) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("iGPSport")
                                    .font(.headline)
                                if igpsportAuthManager.isAuthenticated {
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Not connected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if igpsportAuthManager.isAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Analysis") {
                    NavigationLink(destination: UserProfileView()) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.purple)
                            Text("User Profile")
                        }
                    }
                    
                    NavigationLink(destination: AISettingsView()) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.pink)
                            Text("AI Analysis")
                        }
                    }
                }
                
                Section("Preferences") {
                    NavigationLink(destination: GeneralSettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.gray)
                            Text("General")
                        }
                    }
                    
                    Picker("Language", selection: $languageManager.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                }
                
                Section("Diagnostics") {
                    NavigationLink(destination: NetworkDiagnosticsView()) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Network Diagnostics")
                                    .font(.headline)
                                Text(networkStatusText)
                                    .font(.caption)
                                    .foregroundColor(networkStatusColor)
                            }
                            Spacer()
                            networkStatusIcon
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .frame(minWidth: 250, idealWidth: 300)
            .listStyle(.sidebar)
            
            // Default detail view
            VStack {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Select a setting")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - AI Settings View

struct AISettingsView: View {
    @AppStorage("aiAnalysisEnabled") private var aiAnalysisEnabled = true
    @AppStorage("aiProvider") private var aiProvider = "deepseek"
    @AppStorage("aiAPIKey") private var aiAPIKey = ""
    
    var body: some View {
        Form {
            Section("AI Analysis") {
                Toggle("Enable AI Analysis", isOn: $aiAnalysisEnabled)
                
                if aiAnalysisEnabled {
                    Picker("AI Provider", selection: $aiProvider) {
                        Text("DeepSeek").tag("deepseek")
                        Text("OpenAI").tag("openai")
                        Text("Claude").tag("claude")
                    }
                    .pickerStyle(.segmented)
                    
                    SecureField("API Key", text: $aiAPIKey)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            Section("Analysis Options") {
                Toggle("Auto-analyze new activities", isOn: .constant(false))
                Toggle("Include training recommendations", isOn: .constant(true))
                Toggle("Performance trend analysis", isOn: .constant(true))
            }
            
            Section {
                Text("AI analysis uses your activity data to provide personalized training insights and recommendations.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("AI Analysis")
        .frame(minWidth: 500, maxWidth: .infinity)
        .padding()
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @AppStorage("unitSystem") private var unitSystem = "metric"
    @AppStorage("autoSync") private var autoSync = true
    @AppStorage("syncInterval") private var syncInterval = 3600.0
    @AppStorage("privacyLevel") private var privacyLevel = "standard"
    
    var body: some View {
        Form {
            Section("Units") {
                Picker("Unit System", selection: $unitSystem) {
                    Text("Metric").tag("metric")
                    Text("Imperial").tag("imperial")
                }
                .pickerStyle(.segmented)
            }
            
            Section("Synchronization") {
                Toggle("Auto Sync", isOn: $autoSync)
                
                if autoSync {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sync Interval")
                            .font(.headline)
                        Picker("", selection: $syncInterval) {
                            Text("15 minutes").tag(900.0)
                            Text("30 minutes").tag(1800.0)
                            Text("1 hour").tag(3600.0)
                            Text("2 hours").tag(7200.0)
                            Text("6 hours").tag(21600.0)
                        }
                        #if os(macOS)
                        .pickerStyle(.radioGroup)
                        #else
                        .pickerStyle(.menu)
                        #endif
                    }
                }
            }
            
            Section("Privacy") {
                Picker("Privacy Level", selection: $privacyLevel) {
                    Text("Minimal").tag("minimal")
                    Text("Standard").tag("standard")
                    Text("Full").tag("full")
                }
                #if os(macOS)
                .pickerStyle(.radioGroup)
                #else
                .pickerStyle(.menu)
                #endif
                
                Text(privacyDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Data Management") {
                Button("Clear Cache") {
                    // TODO: Implement cache clearing
                }
                
                Button("Export All Data") {
                    // TODO: Implement data export
                }
                
                Button("Delete All Data", role: .destructive) {
                    // TODO: Implement data deletion
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .frame(minWidth: 500, maxWidth: .infinity)
        .padding()
    }
    
    private var privacyDescription: String {
        switch privacyLevel {
        case "minimal":
            return "Only essential data is shared with external services."
        case "standard":
            return "Activity data is shared for analysis, but personal information is kept private."
        case "full":
            return "All data is shared to provide the best analysis and recommendations."
        default:
            return ""
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StravaAuthManager())
        .environmentObject(IGPSportAuthManager())
        .environmentObject(NetworkPermissionService())
}

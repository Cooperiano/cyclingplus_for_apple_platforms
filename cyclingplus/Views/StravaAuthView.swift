//
//  StravaAuthView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct StravaAuthView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var authManager: StravaAuthManager
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var showingCredentialsSheet = false
    @State private var isAuthenticating = false
    
    init(authManager: StravaAuthManager? = nil) {
        self._authManager = StateObject(wrappedValue: authManager ?? StravaAuthManager())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: isCompact ? 16 : 20) {
                if authManager.isAuthenticated {
                    authenticatedView
                } else {
                    unauthenticatedView
                }
            }
            .padding(isCompact ? 16 : 24)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showingCredentialsSheet) {
            credentialsSheet
        }
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    private var authenticatedView: some View {
        VStack(spacing: isCompact ? 12 : 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isCompact ? 44 : 60))
                .foregroundColor(.green)
            
            Text("Connected to Strava")
                .font(isCompact ? .title3 : .title2)
                .bold()
            
            if let athlete = authManager.currentAthlete {
                VStack(spacing: isCompact ? 6 : 8) {
                    Text(athlete.displayName)
                        .font(.headline)
                    
                    if let city = athlete.city, let state = athlete.state {
                        Text("\(city), \(state)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                .cornerRadius(10)
            }
            
            Button("Disconnect") {
                authManager.logout()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
    }
    
    private var unauthenticatedView: some View {
        VStack(spacing: isCompact ? 18 : 24) {
            VStack(spacing: isCompact ? 8 : 12) {
                Image(systemName: "link.circle")
                    .font(.system(size: isCompact ? 40 : 50))
                    .foregroundColor(.orange)
                
                Text("Connect to Strava")
                    .font(isCompact ? .title2 : .title)
                    .bold()
                
                Text("Sync your cycling activities and analyze your performance data.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: isCompact ? .infinity : 420)
            }
            
            if let error = authManager.authenticationError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red)
                }
                .cardStyle()
            }
            
            VStack(spacing: isCompact ? 12 : 16) {
                Button {
                    showingCredentialsSheet = true
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Configure API Credentials")
                    }
                    .frame(maxWidth: isCompact ? .infinity : 260)
                }
                .buttonStyle(.bordered)
                .controlSize(isCompact ? .regular : .large)
                .padding(.horizontal, isCompact ? 6 : 0)
                
                Button {
                    Task {
                        isAuthenticating = true
                        authManager.authenticationError = nil
                        do {
                            try await authManager.authenticate()
                        } catch {
                            print("Authentication error: \(error)")
                            authManager.authenticationError = error.localizedDescription
                        }
                        isAuthenticating = false
                    }
                } label: {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text(isAuthenticating ? "Connecting..." : "Connect to Strava")
                    }
                    .frame(maxWidth: isCompact ? .infinity : 260)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(isCompact ? .regular : .large)
                .disabled(isAuthenticating)
                .padding(.horizontal, isCompact ? 6 : 0)
            }
            
            VStack(spacing: isCompact ? 2 : 4) {
                Text("After clicking Connect:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("1. Authorize on Strava")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("2. Wait for the browser to close automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("3. The app will finish authentication automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .cardStyle()
        }
        .frame(maxWidth: isCompact ? .infinity : 520, alignment: .center)
    }
    
    private var credentialsSheet: some View {
        ScrollView {
        VStack(spacing: 20) {
            Text("Strava API Configuration")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client ID")
                        .font(.headline)
                    TextField("Enter your Strava Client ID", text: $clientId)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: isCompact ? .infinity : 420)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client Secret")
                        .font(.headline)
                    SecureField("Enter your Strava Client Secret", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: isCompact ? .infinity : 420)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup Instructions:")
                        .font(.headline)
                    
                    Text("1. Visit Strava API Settings")
                        .font(.caption)
                    Link("https://www.strava.com/settings/api", destination: URL(string: "https://www.strava.com/settings/api")!)
                        .font(.caption)
                    
                    Text("2. Set Authorization Callback Domain to: cyclingplus")
                        .font(.caption)
                    
                    Text("3. The app will use: cyclingplus://cyclingplus")
                        .font(.caption)
                    
                    Text("4. Copy your Client ID and Client Secret above")
                        .font(.caption)
                }
                .cardStyle()
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    showingCredentialsSheet = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveCredentials()
                    showingCredentialsSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(clientId.isEmpty || clientSecret.isEmpty)
            }
        }
        .padding(isCompact ? 20 : 30)
        .frame(maxWidth: isCompact ? .infinity : 520)
        .onAppear {
            loadCredentials()
        }
        }
    }
    
    private func saveCredentials() {
        // Use the auth manager's method to save credentials
        authManager.updateCredentials(clientId: clientId, clientSecret: clientSecret)
    }
    
    private func loadCredentials() {
        // Load client ID from UserDefaults
        if let savedClientId = UserDefaults.standard.string(forKey: "strava_client_id") {
            clientId = savedClientId
        }
        
        // Load client secret from Keychain
        let keychainService = "com.cyclingplus.strava.config"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "client_secret",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let secret = String(data: data, encoding: .utf8) {
            clientSecret = secret
        }
    }
}

#Preview {
    StravaAuthView()
}

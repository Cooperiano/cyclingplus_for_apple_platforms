//
//  StravaAuthView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct StravaAuthView: View {
    @StateObject private var authManager: StravaAuthManager
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var authorizationCode = ""
    @State private var showingCredentialsSheet = false
    @State private var showingCodeEntrySheet = false
    @State private var isAuthenticating = false
    
    init(authManager: StravaAuthManager? = nil) {
        self._authManager = StateObject(wrappedValue: authManager ?? StravaAuthManager())
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if authManager.isAuthenticated {
                authenticatedView
            } else {
                unauthenticatedView
            }
        }
        .padding()
        .sheet(isPresented: $showingCredentialsSheet) {
            credentialsSheet
        }
    }
    
    private var authenticatedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Connected to Strava")
                .font(.title2)
                .bold()
            
            if let athlete = authManager.currentAthlete {
                VStack(spacing: 8) {
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
                .cornerRadius(8)
            }
            
            Button("Disconnect") {
                authManager.logout()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
    }
    
    private var unauthenticatedView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "link.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Connect to Strava")
                    .font(.title)
                    .bold()
                
                Text("Sync your cycling activities and analyze your performance data.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            if let error = authManager.authenticationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.callout)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(spacing: 16) {
                Button {
                    showingCredentialsSheet = true
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Configure API Credentials")
                    }
                    .frame(width: 250)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button {
                    Task {
                        isAuthenticating = true
                        do {
                            try await authManager.authenticate()
                        } catch {
                            print("Authentication error: \(error)")
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
                    .frame(width: 250)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isAuthenticating)
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    showingCodeEntrySheet = true
                } label: {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("Enter Authorization Code")
                    }
                    .frame(width: 250)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Text("After clicking Connect, copy the code from the browser URL")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 500)
        .sheet(isPresented: $showingCodeEntrySheet) {
            codeEntrySheet
        }
    }
    
    private var credentialsSheet: some View {
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
                        .frame(width: 400)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client Secret")
                        .font(.headline)
                    SecureField("Enter your Strava Client Secret", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 400)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup Instructions:")
                        .font(.headline)
                    
                    Text("1. Visit Strava API Settings")
                        .font(.caption)
                    Link("https://www.strava.com/settings/api", destination: URL(string: "https://www.strava.com/settings/api")!)
                        .font(.caption)
                    
                    Text("2. Set Authorization Callback Domain to: localhost")
                        .font(.caption)
                    
                    Text("3. The app will use: http://localhost/exchange_token")
                        .font(.caption)
                    
                    Text("4. Copy your Client ID and Client Secret above")
                        .font(.caption)
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
                .cornerRadius(8)
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
        .padding(30)
        .frame(width: 500)
        .onAppear {
            loadCredentials()
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
    
    private var codeEntrySheet: some View {
        VStack(spacing: 20) {
            Text("Enter Authorization Code")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("After authorizing in the browser, you'll be redirected to a URL like:")
                    .font(.caption)
                
                Text("http://localhost/?state=&code=YOUR_CODE_HERE&scope=read,activity:read_all")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                    .cornerRadius(8)
                
                Text("Copy the code parameter from the URL and paste it below:")
                    .font(.caption)
                
                TextField("Paste authorization code here", text: $authorizationCode)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 400)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    showingCodeEntrySheet = false
                    authorizationCode = ""
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Connect") {
                    Task {
                        isAuthenticating = true
                        do {
                            // Create a fake URL with the code
                            let urlString = "http://localhost/?code=\(authorizationCode)"
                            if let url = URL(string: urlString) {
                                try await authManager.handleAuthorizationCallback(url: url)
                                showingCodeEntrySheet = false
                                authorizationCode = ""
                            }
                        } catch {
                            print("Authentication error: \(error)")
                        }
                        isAuthenticating = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(authorizationCode.isEmpty || isAuthenticating)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
}

#Preview {
    StravaAuthView()
}
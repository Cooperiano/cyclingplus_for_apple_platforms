//
//  IGPSportAuthView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct IGPSportAuthView: View {
    @StateObject private var authManager: IGPSportAuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var isAuthenticating = false
    @State private var showPassword = false
    
    init(authManager: IGPSportAuthManager? = nil) {
        self._authManager = StateObject(wrappedValue: authManager ?? IGPSportAuthManager())
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
        .navigationTitle("iGPSport")
    }
    
    private var authenticatedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Connected to iGPSport")
                .font(.title2)
                .bold()
            
            if let username = authManager.currentUsername {
                VStack(spacing: 8) {
                    Text("Logged in as")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(username)
                        .font(.headline)
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
                username = ""
                password = ""
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
                    .foregroundColor(.blue)
                
                Text("Connect to iGPSport")
                    .font(.title)
                    .bold()
                
                Text("Sync your cycling activities from iGPSport devices.")
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.headline)
                    TextField("Enter your iGPSport username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .disableAutocorrection(true)
                        .frame(width: 300)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                    HStack {
                        if showPassword {
                            TextField("Enter your password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                        } else {
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 300)
                }
            }
            
            Button {
                Task {
                    isAuthenticating = true
                    do {
                        _ = try await authManager.authenticate(username: username, password: password)
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
                    Text(isAuthenticating ? "Logging in..." : "Login to iGPSport")
                }
                .frame(width: 250)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(username.isEmpty || password.isEmpty || isAuthenticating)
            
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Connects to iGPSport China (prod.zh.igpsport.com)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("Credentials stored securely in macOS Keychain")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: 500)
    }
}

#Preview {
    NavigationView {
        IGPSportAuthView()
    }
}
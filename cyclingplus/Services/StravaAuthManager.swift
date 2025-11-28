//
//  StravaAuthManager.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import Security
import Combine
#if os(macOS)
import AppKit
#endif

@MainActor
class StravaAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentAthlete: StravaAthlete?
    @Published var authenticationError: String?
    
    private let keychainService = "com.cyclingplus.strava"
    private let credentialsKey = "strava_credentials"
    
    // Strava OAuth configuration
    private let clientId: String
    private let clientSecret: String
    private let redirectURI: String
    private let scope = "read,activity:read_all"
    
    init(clientId: String = "", clientSecret: String = "", redirectURI: String = "http://localhost/exchange_token") {
        // Try to load from storage first
        let loadedClientId = UserDefaults.standard.string(forKey: "strava_client_id") ?? clientId
        let loadedClientSecret = Self.loadClientSecretFromKeychain() ?? clientSecret
        
        self.clientId = loadedClientId.isEmpty ? clientId : loadedClientId
        self.clientSecret = loadedClientSecret.isEmpty ? clientSecret : loadedClientSecret
        self.redirectURI = redirectURI
        
        // Check if we have stored credentials on init
        Task {
            await checkStoredCredentials()
        }
    }
    
    // Public method to update credentials
    func updateCredentials(clientId: String, clientSecret: String) {
        // Save to UserDefaults
        UserDefaults.standard.set(clientId, forKey: "strava_client_id")
        
        // Save client secret to Keychain
        let keychainService = "com.cyclingplus.strava.config"
        if let secretData = clientSecret.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: "client_secret",
                kSecValueData as String: secretData
            ]
            
            // Delete existing item first
            SecItemDelete(query as CFDictionary)
            
            // Add new item
            SecItemAdd(query as CFDictionary, nil)
        }
    }
    
    // Public method to check if credentials are configured
    var hasCredentials: Bool {
        return !clientId.isEmpty && !clientSecret.isEmpty
    }
    
    private static func loadClientSecretFromKeychain() -> String? {
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
            return secret
        }
        
        return nil
    }
    
    // MARK: - Public Authentication Methods
    
    func authenticate() async throws {
        guard !clientId.isEmpty && !clientSecret.isEmpty else {
            throw CyclingPlusError.authenticationFailed("Strava client credentials not configured")
        }
        
        let authURL = buildAuthorizationURL()
        
        // Open the authorization URL in the system browser
        #if os(macOS)
        NSWorkspace.shared.open(authURL)
        #endif
        
        // The actual token exchange will happen when the redirect URL is handled
    }
    
    func handleAuthorizationCallback(url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw CyclingPlusError.authenticationFailed("Invalid callback URL")
        }
        
        // Check for error in callback
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            throw CyclingPlusError.authenticationFailed("Authorization failed: \(error)")
        }
        
        // Extract authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            throw CyclingPlusError.authenticationFailed("No authorization code received")
        }
        
        // Exchange code for tokens
        try await exchangeCodeForTokens(code: code)
    }
    
    func refreshTokenIfNeeded() async throws {
        guard let credentials = getStoredCredentials() else {
            throw CyclingPlusError.authenticationFailed("No stored credentials")
        }
        
        if credentials.isExpired {
            try await refreshAccessToken(refreshToken: credentials.refreshToken)
        }
    }
    
    func logout() {
        deleteStoredCredentials()
        isAuthenticated = false
        currentAthlete = nil
        authenticationError = nil
    }
    
    // MARK: - Private Methods
    
    private func buildAuthorizationURL() -> URL {
        var components = URLComponents(string: "https://www.strava.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "approval_prompt", value: "auto")
        ]
        return components.url!
    }
    
    private func exchangeCodeForTokens(code: String) async throws {
        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CyclingPlusError.stravaAPIError("Token exchange failed")
            }
            
            let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
            let credentials = tokenResponse.toCredentials()
            
            // Store credentials securely
            storeCredentials(credentials)
            
            // Fetch athlete profile
            try await fetchAthleteProfile(accessToken: credentials.accessToken)
            
            isAuthenticated = true
        } catch let error as URLError {
            // Check for network permission errors
            if error.code == .notConnectedToInternet || error.code == .cannotConnectToHost {
                if let underlyingError = error.errorUserInfo[NSUnderlyingErrorKey] as? NSError,
                   underlyingError.domain == NSPOSIXErrorDomain,
                   underlyingError.code == 1 {
                    throw CyclingPlusError.networkPermissionDenied("Network access is not permitted. The app may be missing network client entitlements or system proxy settings may be blocking the connection.")
                }
            }
            throw error
        }
    }
    
    private func refreshAccessToken(refreshToken: String) async throws {
        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CyclingPlusError.stravaAPIError("Token refresh failed")
            }
            
            let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
            let credentials = tokenResponse.toCredentials()
            
            // Update stored credentials
            storeCredentials(credentials)
        } catch let error as URLError {
            // Check for network permission errors
            if error.code == .notConnectedToInternet || error.code == .cannotConnectToHost {
                if let underlyingError = error.errorUserInfo[NSUnderlyingErrorKey] as? NSError,
                   underlyingError.domain == NSPOSIXErrorDomain,
                   underlyingError.code == 1 {
                    throw CyclingPlusError.networkPermissionDenied("Network access is not permitted. The app may be missing network client entitlements or system proxy settings may be blocking the connection.")
                }
            }
            throw error
        }
    }
    
    private func fetchAthleteProfile(accessToken: String) async throws {
        let url = URL(string: "https://www.strava.com/api/v3/athlete")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CyclingPlusError.stravaAPIError("Failed to fetch athlete profile")
            }
            
            currentAthlete = try JSONDecoder().decode(StravaAthlete.self, from: data)
        } catch let error as URLError {
            // Check for network permission errors
            if error.code == .notConnectedToInternet || error.code == .cannotConnectToHost {
                if let underlyingError = error.errorUserInfo[NSUnderlyingErrorKey] as? NSError,
                   underlyingError.domain == NSPOSIXErrorDomain,
                   underlyingError.code == 1 {
                    throw CyclingPlusError.networkPermissionDenied("Network access is not permitted. The app may be missing network client entitlements or system proxy settings may be blocking the connection.")
                }
            }
            throw error
        }
    }
    
    private func checkStoredCredentials() async {
        guard let credentials = getStoredCredentials() else {
            return
        }
        
        do {
            if credentials.isExpired {
                try await refreshAccessToken(refreshToken: credentials.refreshToken)
            }
            
            try await fetchAthleteProfile(accessToken: credentials.accessToken)
            isAuthenticated = true
        } catch {
            // If refresh fails, clear stored credentials
            deleteStoredCredentials()
            authenticationError = error.localizedDescription
        }
    }
    
    // MARK: - Keychain Methods
    
    private func storeCredentials(_ credentials: StravaCredentials) {
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: credentialsKey,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getStoredCredentials() -> StravaCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: credentialsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(StravaCredentials.self, from: data) else {
            return nil
        }
        
        return credentials
    }
    
    private func deleteStoredCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: credentialsKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Public Getters
    
    func getValidAccessToken() async throws -> String {
        try await refreshTokenIfNeeded()
        
        guard let credentials = getStoredCredentials() else {
            throw CyclingPlusError.authenticationFailed("No valid credentials")
        }
        
        return credentials.accessToken
    }
}

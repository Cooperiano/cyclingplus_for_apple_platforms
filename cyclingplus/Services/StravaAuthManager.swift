//
//  StravaAuthManager.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import Security
import Combine
import AuthenticationServices
#if os(macOS)
import AppKit
#endif

@MainActor
class StravaAuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentAthlete: StravaAthlete?
    @Published var authenticationError: String?
    
    private let keychainService = "com.cyclingplus.strava"
    private let credentialsKey = "strava_credentials"
    private var authSession: ASWebAuthenticationSession?
    private var trimmedClientId: String { clientId.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedClientSecret: String { clientSecret.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    // Strava OAuth configuration
    private var clientId: String
    private var clientSecret: String
    private let redirectURI: String
    private let scope = "read,activity:read_all"
    
    init(clientId: String = "", clientSecret: String = "", redirectURI: String = "cyclingplus://cyclingplus") {
        // Try to load from storage first
        let loadedClientId = UserDefaults.standard.string(forKey: "strava_client_id") ?? clientId
        let loadedClientSecret = Self.loadClientSecretFromKeychain() ?? clientSecret
        
        self.clientId = loadedClientId.isEmpty ? clientId : loadedClientId
        self.clientSecret = loadedClientSecret.isEmpty ? clientSecret : loadedClientSecret
        self.redirectURI = redirectURI
        
        super.init()
        
        // Check if we have stored credentials on init
        Task {
            await checkStoredCredentials()
        }
    }
    
    // Public method to update credentials
    func updateCredentials(clientId: String, clientSecret: String) {
        self.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.clientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)

        // Save to UserDefaults
        UserDefaults.standard.set(self.clientId, forKey: "strava_client_id")
        
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
        guard !trimmedClientId.isEmpty && !trimmedClientSecret.isEmpty else {
            throw CyclingPlusError.authenticationFailed("Strava client credentials not configured")
        }
        
        let callbackScheme = URL(string: redirectURI)?.scheme ?? "cyclingplus"
        let authURL = buildAuthorizationURL()

        print("🔐 Starting ASWebAuthenticationSession...")
        print("   Auth URL: \(authURL.absoluteString)")
        print("   Callback scheme: \(callbackScheme)")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: CyclingPlusError.authenticationFailed("No callback URL received"))
                    return
                }

                Task { [weak self] in
                    guard let self else {
                        continuation.resume(throwing: CyclingPlusError.authenticationFailed("Authentication manager no longer available"))
                        return
                    }

                    do {
                        try await self.handleAuthorizationCallback(url: callbackURL)
                        continuation.resume(returning: ())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            guard let authSession else {
                continuation.resume(throwing: CyclingPlusError.authenticationFailed("Failed to create authentication session"))
                return
            }

            #if os(macOS)
            authSession.presentationContextProvider = self
            #endif
            authSession.prefersEphemeralWebBrowserSession = true

            if !authSession.start() {
                continuation.resume(throwing: CyclingPlusError.authenticationFailed("Failed to start authentication session"))
            }
        }
    }
    
    func handleAuthorizationCallback(url: URL) async throws {
        print("🔐 StravaAuthManager: Processing callback URL")
        print("   URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ Failed to parse URL components")
            throw CyclingPlusError.authenticationFailed("Invalid callback URL")
        }
        
        print("   Query items: \(queryItems.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: ", "))")
        
        // Check for error in callback
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            print("❌ Authorization error: \(error)")
            throw CyclingPlusError.authenticationFailed("Authorization failed: \(error)")
        }
        
        // Extract authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            print("❌ No authorization code in callback")
            throw CyclingPlusError.authenticationFailed("No authorization code received")
        }
        
        print("✅ Authorization code received: \(code.prefix(10))...")
        
        // Exchange code for tokens
        print("🔄 Exchanging code for tokens...")
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
            URLQueryItem(name: "client_id", value: trimmedClientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "approval_prompt", value: "auto")
        ]
        return components.url!
    }
    
    private func exchangeCodeForTokens(code: String) async throws {
        print("🌐 Making token exchange request to Strava...")
        
        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": trimmedClientId,
            "client_secret": trimmedClientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw CyclingPlusError.stravaAPIError("Invalid response from server")
            }
            
            print("📡 HTTP Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorString)")
                }
                throw CyclingPlusError.stravaAPIError("Token exchange failed with status \(httpResponse.statusCode)")
            }
            
            print("✅ Token exchange successful")
            
            let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
            let credentials = tokenResponse.toCredentials()
            
            print("💾 Storing credentials...")
            storeCredentials(credentials)
            
            print("👤 Fetching athlete profile...")
            try await fetchAthleteProfile(accessToken: credentials.accessToken)
            
            isAuthenticated = true
            print("✅ Authentication complete!")
        } catch let error as URLError {
            print("❌ Network error: \(error.localizedDescription)")
            // Check for network permission errors
            if error.code == .notConnectedToInternet || error.code == .cannotConnectToHost {
                if let underlyingError = error.errorUserInfo[NSUnderlyingErrorKey] as? NSError,
                   underlyingError.domain == NSPOSIXErrorDomain,
                   underlyingError.code == 1 {
                    throw CyclingPlusError.networkPermissionDenied("Network access is not permitted. The app may be missing network client entitlements or system proxy settings may be blocking the connection.")
                }
            }
            throw error
        } catch {
            print("❌ Unexpected error: \(error)")
            throw error
        }
    }
    
    @discardableResult
    private func refreshAccessToken(refreshToken: String) async throws -> StravaCredentials {
        let url = URL(string: "https://www.strava.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": trimmedClientId,
            "client_secret": trimmedClientSecret,
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
            return credentials
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
            var currentCredentials = credentials
            if credentials.isExpired {
                currentCredentials = try await refreshAccessToken(refreshToken: credentials.refreshToken)
            }
            
            try await fetchAthleteProfile(accessToken: currentCredentials.accessToken)
            isAuthenticated = true
        } catch {
            // Only clear credentials on authentication failures; keep on network errors
            if case CyclingPlusError.authenticationFailed = error {
                deleteStoredCredentials()
            }
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

// MARK: - ASWebAuthenticationPresentationContextProviding

#if os(macOS)
extension StravaAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first!
    }
}
#endif

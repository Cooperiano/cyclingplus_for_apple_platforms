//
//  IGPSportAuthManager.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import Security
import Combine

@MainActor
class IGPSportAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUsername: String?
    @Published var authenticationError: String?
    
    private let keychainService = "com.cyclingplus.igpsport"
    private let credentialsKey = "igpsport_credentials"
    private let baseURL = "https://prod.zh.igpsport.com/service"
    
    private var urlSession: URLSession
    
    init() {
        // Configure URL session with retry policy
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 60
        
        self.urlSession = URLSession(configuration: configuration)
        
        // Check if we have stored credentials on init
        Task {
            await checkStoredCredentials()
        }
    }
    
    // MARK: - Public Authentication Methods
    
    func authenticate(username: String, password: String) async throws -> IGPSportCredentials {
        guard !username.isEmpty && !password.isEmpty else {
            throw CyclingPlusError.authenticationFailed("Username and password are required")
        }
        
        let url = URL(string: "\(baseURL)/auth/account/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("igps-cn-export/1.0 (+requests)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("https://login.passport.igpsport.cn", forHTTPHeaderField: "Origin")
        request.setValue("https://login.passport.igpsport.cn/", forHTTPHeaderField: "Referer")
        
        let loginData = [
            "username": username,
            "password": password,
            "appId": "igpsport-web"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CyclingPlusError.igpsportAPIError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CyclingPlusError.igpsportAPIError("Login failed with status \(httpResponse.statusCode)")
        }
        
        let loginResponse = try JSONDecoder().decode(IGPSportLoginResponse.self, from: data)
        
        guard loginResponse.code == 0, let loginData = loginResponse.data else {
            let errorMessage = loginResponse.message ?? "Login failed"
            throw CyclingPlusError.authenticationFailed(errorMessage)
        }
        
        let credentials = IGPSportCredentials(
            username: username,
            password: password,
            accessToken: loginData.accessToken,
            loginTime: Date()
        )
        
        // Store credentials securely
        storeCredentials(credentials)
        
        // Update authentication state
        isAuthenticated = true
        currentUsername = username
        authenticationError = nil
        
        return credentials
    }
    
    func refreshSession() async throws {
        guard let credentials = getStoredCredentials() else {
            throw CyclingPlusError.authenticationFailed("No stored credentials")
        }
        
        if credentials.isExpired {
            // Re-authenticate with stored credentials
            _ = try await authenticate(username: credentials.username, password: credentials.password)
        }
    }
    
    func logout() {
        deleteStoredCredentials()
        isAuthenticated = false
        currentUsername = nil
        authenticationError = nil
    }
    
    // MARK: - Private Methods
    
    private func checkStoredCredentials() async {
        guard let credentials = getStoredCredentials() else {
            return
        }
        
        do {
            if credentials.isExpired {
                try await refreshSession()
            } else {
                // Test the session with a simple API call
                if await testSession(credentials: credentials) {
                    isAuthenticated = true
                    currentUsername = credentials.username
                } else {
                    // Session invalid, try to refresh
                    try await refreshSession()
                }
            }
        } catch {
            // If refresh fails, clear stored credentials
            deleteStoredCredentials()
            authenticationError = error.localizedDescription
        }
    }
    
    private func testSession(credentials: IGPSportCredentials) async -> Bool {
        guard let accessToken = credentials.accessToken else { return false }
        
        let url = URL(string: "\(baseURL)/web-gateway/web-analyze/activity/queryMyActivity?pageNo=1&pageSize=1&reqType=0&sort=1")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("igps-cn-export/1.0 (+requests)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            // Check HTTP status code
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }
            
            // Check response code in JSON body
            let probeResponse = try JSONDecoder().decode(IGPSportActivityListResponse.self, from: data)
            return probeResponse.code == 0
        } catch {
            return false
        }
    }
    
    // MARK: - Keychain Methods
    
    private func storeCredentials(_ credentials: IGPSportCredentials) {
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
    
    private func getStoredCredentials() -> IGPSportCredentials? {
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
              let credentials = try? JSONDecoder().decode(IGPSportCredentials.self, from: data) else {
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
    
    func getValidCredentials() async throws -> IGPSportCredentials {
        try await refreshSession()
        
        guard let credentials = getStoredCredentials() else {
            throw CyclingPlusError.authenticationFailed("No valid credentials")
        }
        
        return credentials
    }
}
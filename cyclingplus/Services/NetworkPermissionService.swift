//
//  NetworkPermissionService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/8.
//

import Foundation
import Combine
import os.log

@MainActor
class NetworkPermissionService: ObservableObject {
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var lastTestResult: TestResult?
    
    private let logger = Logger(subsystem: "com.cyclingplus", category: "NetworkPermission")
    
    enum NetworkStatus {
        case unknown
        case available
        case restricted
        case unavailable
    }
    
    struct TestResult {
        let success: Bool
        let message: String
        let timestamp: Date
        let details: String?
    }
    
    // MARK: - Public Methods
    
    /// Verify network permissions at app startup
    func verifyNetworkPermissions() async {
        logger.info("🔍 Starting network permission verification...")
        
        // Check entitlements
        let hasNetworkEntitlement = checkNetworkEntitlement()
        logger.info("📋 Network client entitlement: \(hasNetworkEntitlement ? "✅ Present" : "❌ Missing")")
        
        // Test basic connectivity
        await testNetworkConnectivity()
        
        // Log final status
        logNetworkStatus()
    }
    
    /// Test network connectivity with a simple request
    func testNetworkConnection() async -> TestResult {
        logger.info("🧪 Testing network connection...")
        
        let testURL = URL(string: "https://www.strava.com/api/v3/athlete")!
        var request = URLRequest(url: testURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode < 500
                let message = success ? "Network connection successful" : "Server error"
                let details = "Status code: \(httpResponse.statusCode)"
                
                logger.info("✅ Network test successful: \(details)")
                
                networkStatus = .available
                let result = TestResult(
                    success: success,
                    message: message,
                    timestamp: Date(),
                    details: details
                )
                lastTestResult = result
                return result
            }
            
            let result = TestResult(
                success: false,
                message: "Invalid response",
                timestamp: Date(),
                details: "Response was not HTTP"
            )
            lastTestResult = result
            return result
            
        } catch let error as URLError {
            return await handleURLError(error)
        } catch {
            logger.error("❌ Network test failed: \(error.localizedDescription)")
            
            networkStatus = .unavailable
            let result = TestResult(
                success: false,
                message: "Network test failed",
                timestamp: Date(),
                details: error.localizedDescription
            )
            lastTestResult = result
            return result
        }
    }
    
    // MARK: - Private Methods
    
    private func checkNetworkEntitlement() -> Bool {
        // On iOS, we cannot directly check entitlements at runtime like on macOS
        // Instead, we assume the entitlement is present if the app is properly configured
        // The actual network permission will be verified through connectivity tests
        #if os(macOS)
        // macOS-specific entitlement check using codesign
        let task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = ["-d", "--entitlements", "-", Bundle.main.bundlePath]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("com.apple.security.network.client")
            }
        } catch {
            logger.warning("⚠️ Could not verify entitlements: \(error.localizedDescription)")
        }
        
        return false
        #else
        // On iOS, network access is granted by default for apps
        // We'll verify actual connectivity through network tests
        return true
        #endif
    }
    
    private func testNetworkConnectivity() async {
        let result = await testNetworkConnection()
        
        if result.success {
            logger.info("✅ Network connectivity verified")
            networkStatus = .available
        } else {
            logger.warning("⚠️ Network connectivity issue detected: \(result.message)")
            
            if result.details?.contains("Operation not permitted") == true ||
               result.details?.contains("NSPOSIXErrorDomain") == true {
                networkStatus = .restricted
                logger.error("❌ NETWORK PERMISSION DENIED - App may be missing network client entitlements")
            } else {
                networkStatus = .unavailable
            }
        }
    }
    
    private func handleURLError(_ error: URLError) async -> TestResult {
        var message = "Network error"
        var details = error.localizedDescription
        
        // Check for permission-related errors
        if error.code == .notConnectedToInternet || error.code == .cannotConnectToHost {
            if let underlyingError = error.errorUserInfo[NSUnderlyingErrorKey] as? NSError,
               underlyingError.domain == NSPOSIXErrorDomain,
               underlyingError.code == 1 {
                message = "Network permission denied"
                details = "Operation not permitted (POSIX error 1). The app is missing network client entitlements or system proxy settings are blocking the connection."
                networkStatus = .restricted
                
                logger.error("❌ NETWORK PERMISSION DENIED")
                logger.error("   Error: \(details)")
                logger.error("   Solution: Ensure 'com.apple.security.network.client' entitlement is present")
            } else {
                message = "Network unavailable"
                details = "Cannot connect to host. Check internet connection or proxy settings."
                networkStatus = .unavailable
                
                logger.warning("⚠️ Network unavailable: \(details)")
            }
        } else if error.code == .timedOut {
            message = "Connection timeout"
            details = "Request timed out. Check proxy server if configured."
            networkStatus = .unavailable
            
            logger.warning("⚠️ Connection timeout")
        } else {
            networkStatus = .unavailable
            logger.error("❌ Network error: \(error.code.rawValue) - \(details)")
        }
        
        let result = TestResult(
            success: false,
            message: message,
            timestamp: Date(),
            details: details
        )
        lastTestResult = result
        return result
    }
    
    private func logNetworkStatus() {
        let status = self.networkStatus
        let result = self.lastTestResult
        
        logger.info("📊 Network Status Summary:")
        logger.info("   Status: \(String(describing: status))")
        
        if let result = result {
            logger.info("   Last Test: \(result.success ? "✅ Success" : "❌ Failed")")
            logger.info("   Message: \(result.message)")
            if let details = result.details {
                logger.info("   Details: \(details)")
            }
        }
        
        switch status {
        case .available:
            logger.info("✅ Network permissions are properly configured")
        case .restricted:
            logger.error("❌ Network access is RESTRICTED - Check entitlements configuration")
        case .unavailable:
            logger.warning("⚠️ Network is UNAVAILABLE - Check internet connection or proxy settings")
        case .unknown:
            logger.info("❓ Network status is UNKNOWN - Verification not yet performed")
        }
    }
}

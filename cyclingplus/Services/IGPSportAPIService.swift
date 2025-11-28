//
//  IGPSportAPIService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import Combine

@MainActor
class IGPSportAPIService: ObservableObject {
    private let authManager: IGPSportAuthManager
    private let baseURL = "https://prod.zh.igpsport.com/service"
    
    @Published var isLoading = false
    @Published var lastError: Error?
    
    private var urlSession: URLSession
    
    init(authManager: IGPSportAuthManager) {
        self.authManager = authManager
        
        // Configure URL session with retry policy and timeouts
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 60
        
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - Retry Logic
    
    /// Executes a network request with retry logic and exponential backoff
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts (default: 3)
    ///   - operation: The async operation to retry
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all attempts fail
    private func withRetry<T>(maxAttempts: Int = 3, operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on authentication errors
                if case CyclingPlusError.authenticationFailed = error {
                    throw error
                }
                
                // Don't retry on the last attempt
                if attempt == maxAttempts {
                    break
                }
                
                // Calculate exponential backoff delay: 1.2s, 2.4s, 3.6s
                let delaySeconds = Double(attempt) * 1.2
                let delayNanoseconds = UInt64(delaySeconds * 1_000_000_000)
                
                print("IGPSportAPIService: Request failed (attempt \(attempt)/\(maxAttempts)), retrying in \(delaySeconds)s...")
                
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }
        }
        
        // If we get here, all attempts failed
        throw lastError ?? CyclingPlusError.igpsportAPIError("Request failed after \(maxAttempts) attempts")
    }
    
    // MARK: - Activities
    
    func fetchActivities(page: Int = 1, pageSize: Int = 20) async throws -> [IGPSportActivity] {
        isLoading = true
        defer { isLoading = false }
        
        return try await withRetry {
            let credentials = try await self.authManager.getValidCredentials()
            
            guard let accessToken = credentials.accessToken else {
                throw CyclingPlusError.authenticationFailed("No access token available")
            }
            
            var components = URLComponents(string: "\(self.baseURL)/web-gateway/web-analyze/activity/queryMyActivity")!
            components.queryItems = [
                URLQueryItem(name: "pageNo", value: String(page)),
                URLQueryItem(name: "pageSize", value: String(pageSize)),
                URLQueryItem(name: "reqType", value: "0"),
                URLQueryItem(name: "sort", value: "1")
            ]
            
            var request = URLRequest(url: components.url!)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("igps-cn-export/1.0 (+requests)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await self.urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CyclingPlusError.igpsportAPIError("Invalid response")
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                let activityResponse = try JSONDecoder().decode(IGPSportActivityListResponse.self, from: data)
                
                // Check API response code
                guard activityResponse.code == 0 else {
                    let errorMessage = activityResponse.message ?? "Failed to fetch activities"
                    throw CyclingPlusError.igpsportAPIError("API Error: \(errorMessage)")
                }
                
                return activityResponse.data?.rows ?? []
                
            case 401:
                throw CyclingPlusError.authenticationFailed("Session expired")
            case 403:
                throw CyclingPlusError.igpsportAPIError("Access forbidden - please check authentication headers")
            case 429:
                throw CyclingPlusError.igpsportAPIError("Rate limit exceeded - please try again later")
            default:
                throw CyclingPlusError.igpsportAPIError("HTTP \(httpResponse.statusCode)")
            }
        }
    }
    
    func fetchActivityDetail(rideId: Int) async throws -> IGPSportActivityDetail {
        isLoading = true
        defer { isLoading = false }
        
        return try await withRetry {
            let credentials = try await self.authManager.getValidCredentials()
            
            guard let accessToken = credentials.accessToken else {
                throw CyclingPlusError.authenticationFailed("No access token available")
            }
            
            let url = URL(string: "\(self.baseURL)/web-gateway/web-analyze/activity/queryActivityDetail/\(rideId)")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("igps-cn-export/1.0 (+requests)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await self.urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CyclingPlusError.igpsportAPIError("Invalid response")
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                let detailResponse = try JSONDecoder().decode(IGPSportActivityDetailResponse.self, from: data)
                
                // Check API response code
                guard detailResponse.code == 0, let detail = detailResponse.data else {
                    let errorMessage = detailResponse.message ?? "Failed to fetch activity detail"
                    throw CyclingPlusError.igpsportAPIError("API Error: \(errorMessage)")
                }
                
                return detail
                
            case 401:
                throw CyclingPlusError.authenticationFailed("Session expired")
            case 403:
                throw CyclingPlusError.igpsportAPIError("Access forbidden - please check authentication headers")
            case 404:
                throw CyclingPlusError.igpsportAPIError("Activity not found")
            case 429:
                throw CyclingPlusError.igpsportAPIError("Rate limit exceeded - please try again later")
            default:
                throw CyclingPlusError.igpsportAPIError("HTTP \(httpResponse.statusCode)")
            }
        }
    }
    
    func downloadFITFile(from urlString: String) async throws -> Data {
        isLoading = true
        defer { isLoading = false }
        
        return try await withRetry {
            guard let url = URL(string: urlString) else {
                throw CyclingPlusError.igpsportAPIError("Invalid FIT file URL")
            }
            
            // FIT files might be on different domains (OSS), so we use a separate request
            // Note: No Authorization header for external URLs (OSS storage)
            var request = URLRequest(url: url)
            request.setValue("igps-cn-export/1.0 (+requests)", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await self.urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CyclingPlusError.igpsportAPIError("Invalid response")
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                guard !data.isEmpty else {
                    throw CyclingPlusError.igpsportAPIError("Empty FIT file")
                }
                return data
                
            case 403:
                throw CyclingPlusError.igpsportAPIError("Access forbidden to FIT file")
            case 404:
                throw CyclingPlusError.igpsportAPIError("FIT file not found")
            case 429:
                throw CyclingPlusError.igpsportAPIError("Rate limit exceeded - please try again later")
            default:
                throw CyclingPlusError.igpsportAPIError("Failed to download FIT file: HTTP \(httpResponse.statusCode)")
            }
        }
    }
    
    /// Get FIT file URL for an activity, fetching detail if needed
    /// Checks multiple field names in order: fitOssPath, fitUrl, fitPath, fitDownloadUrl, fitOssUrl, fit
    func getFITFileURL(for activity: IGPSportActivity) async throws -> String? {
        // First check if the activity already has a FIT URL
        if let fitURL = activity.fitFileURL {
            return fitURL
        }
        
        // If not found in list response, fetch activity detail
        let detail = try await fetchActivityDetail(rideId: activity.rideId)
        return detail.fitFileURL
    }
    
    // MARK: - Utility Methods
    
    func convertIGPSportActivityToLocal(_ igpsActivity: IGPSportActivity) -> Activity {
        return igpsActivity.toActivity()
    }
    
    func syncActivitiesInDateRange(from startDate: Date, to endDate: Date, maxPages: Int = 50) async throws -> [IGPSportActivity] {
        var allActivities: [IGPSportActivity] = []
        var currentPage = 1
        
        while currentPage <= maxPages {
            let activities = try await fetchActivities(page: currentPage, pageSize: 20)
            
            if activities.isEmpty {
                break // No more activities
            }
            
            // Filter activities by date range
            let filteredActivities = activities.filter { activity in
                let activityDate = activity.toActivity().startDate
                return activityDate >= startDate && activityDate <= endDate
            }
            
            allActivities.append(contentsOf: filteredActivities)
            
            // If we got fewer activities than requested, we've reached the end
            if activities.count < 20 {
                break
            }
            
            // Check if the oldest activity in this page is before our start date
            if let oldestActivity = activities.last {
                let oldestDate = oldestActivity.toActivity().startDate
                if oldestDate < startDate {
                    break // We've gone past our date range
                }
            }
            
            currentPage += 1
            
            // Add a small delay to be respectful to the API
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
        }
        
        return allActivities
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: Error) {
        lastError = error
    }
}
//
//  StravaAPIService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import Combine

@MainActor
class StravaAPIService: ObservableObject {
    private let authManager: StravaAuthManager
    private let baseURL = "https://www.strava.com/api/v3"
    
    @Published var isLoading = false
    @Published var lastError: Error?
    
    init(authManager: StravaAuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Activities
    
    func fetchActivities(page: Int = 1, perPage: Int = 30) async throws -> [StravaActivity] {
        isLoading = true
        defer { isLoading = false }
        
        let accessToken = try await authManager.getValidAccessToken()
        
        var components = URLComponents(string: "\(baseURL)/athlete/activities")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CyclingPlusError.stravaAPIError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let activities = try JSONDecoder().decode([StravaActivity].self, from: data)
                return activities
            case 401:
                throw CyclingPlusError.authenticationFailed("Invalid or expired token")
            case 429:
                throw CyclingPlusError.stravaAPIError("Rate limit exceeded")
            default:
                throw CyclingPlusError.stravaAPIError("HTTP \(httpResponse.statusCode)")
            }
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
    
    func fetchActivityDetail(activityId: Int) async throws -> StravaActivity {
        isLoading = true
        defer { isLoading = false }
        
        let accessToken = try await authManager.getValidAccessToken()
        
        let url = URL(string: "\(baseURL)/activities/\(activityId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CyclingPlusError.stravaAPIError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(StravaActivity.self, from: data)
            case 401:
                throw CyclingPlusError.authenticationFailed("Invalid or expired token")
            case 404:
                throw CyclingPlusError.stravaAPIError("Activity not found")
            default:
                throw CyclingPlusError.stravaAPIError("HTTP \(httpResponse.statusCode)")
            }
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
    
    func fetchActivityStreams(activityId: Int, streamTypes: [String] = ["time", "distance", "latlng", "altitude", "velocity_smooth", "heartrate", "cadence", "watts", "temp", "moving", "grade_smooth"]) async throws -> StravaActivityStreams {
        isLoading = true
        defer { isLoading = false }
        
        let accessToken = try await authManager.getValidAccessToken()
        
        var components = URLComponents(string: "\(baseURL)/activities/\(activityId)/streams")!
        components.queryItems = [
            URLQueryItem(name: "keys", value: streamTypes.joined(separator: ",")),
            URLQueryItem(name: "key_by_type", value: "true")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CyclingPlusError.stravaAPIError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(StravaActivityStreams.self, from: data)
            case 401:
                throw CyclingPlusError.authenticationFailed("Invalid or expired token")
            case 404:
                throw CyclingPlusError.stravaAPIError("Activity streams not found")
            default:
                throw CyclingPlusError.stravaAPIError("HTTP \(httpResponse.statusCode)")
            }
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
    
    // MARK: - Athlete
    
    func fetchAthleteProfile() async throws -> StravaAthlete {
        isLoading = true
        defer { isLoading = false }
        
        let accessToken = try await authManager.getValidAccessToken()
        
        let url = URL(string: "\(baseURL)/athlete")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CyclingPlusError.stravaAPIError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(StravaAthlete.self, from: data)
            case 401:
                throw CyclingPlusError.authenticationFailed("Invalid or expired token")
            default:
                throw CyclingPlusError.stravaAPIError("HTTP \(httpResponse.statusCode)")
            }
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
    
    // MARK: - Utility Methods
    
    func convertStravaActivityToLocal(_ stravaActivity: StravaActivity, streams: StravaActivityStreams? = nil) -> (Activity, ActivityStreams?) {
        let activity = stravaActivity.toActivity()
        
        var activityStreams: ActivityStreams? = nil
        
        if let streams = streams {
            // Convert Strava streams to our format while keeping sample indices aligned
            var timeData = streams.time?.data.compactMap { $0.doubleValue } ?? []
            
            let fallbackCount = [
                streams.watts?.data.count ?? 0,
                streams.heartrate?.data.count ?? 0,
                streams.cadence?.data.count ?? 0,
                streams.velocitySmooth?.data.count ?? 0,
                streams.altitude?.data.count ?? 0
            ].max() ?? 0
            
            if timeData.isEmpty, fallbackCount > 0 {
                timeData = (0..<fallbackCount).map { Double($0) }
            }
            
            let sampleCount = timeData.count
            guard sampleCount > 0 else {
                return (activity, nil)
            }
            
            func alignDoubleStream(_ source: StravaStream?) -> [Double?]? {
                guard sampleCount > 0 else { return nil }
                var aligned = Array<Double?>(repeating: 0, count: sampleCount)
                
                guard let source else {
                    return aligned
                }
                
                let limit = min(sampleCount, source.data.count)
                for index in 0..<limit {
                    aligned[index] = source.data[index].doubleValue ?? 0
                }
                return aligned
            }
            
            func alignIntStream(_ source: StravaStream?) -> [Int?]? {
                guard sampleCount > 0 else { return nil }
                var aligned = Array<Int?>(repeating: 0, count: sampleCount)
                
                guard let source else {
                    return aligned
                }
                
                let limit = min(sampleCount, source.data.count)
                for index in 0..<limit {
                    aligned[index] = source.data[index].intValue ?? 0
                }
                return aligned
            }
            
            let powerData = alignDoubleStream(streams.watts)
            let heartRateData = alignIntStream(streams.heartrate)
            let cadenceData = alignIntStream(streams.cadence)
            let speedData = alignDoubleStream(streams.velocitySmooth)
            let elevationData = alignDoubleStream(streams.altitude)
            
            // Convert lat/lng coordinates
            var latLngData: [LatLng]? = nil
            if let latlngStream = streams.latlng?.data {
                latLngData = latlngStream.compactMap { streamValue in
                    guard let coords = streamValue.coordinateValue,
                          coords.count >= 2 else { return nil }
                    return LatLng(latitude: coords[0], longitude: coords[1])
                }
            }
            
            activityStreams = ActivityStreams(
                activityId: activity.id,
                timeData: timeData,
                powerData: powerData,
                heartRateData: heartRateData,
                cadenceData: cadenceData,
                speedData: speedData,
                elevationData: elevationData,
                latLngData: latLngData
            )
        }
        
        return (activity, activityStreams)
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: Error) {
        lastError = error
    }
}

//
//  IGPSportModels.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation

// MARK: - Authentication Models

struct IGPSportCredentials: Codable {
    let username: String
    let password: String
    let accessToken: String?
    let loginTime: Date
    
    var isExpired: Bool {
        // iGPSport sessions typically expire after 24 hours
        Date().timeIntervalSince(loginTime) > 24 * 3600
    }
}

struct IGPSportLoginResponse: Codable {
    let code: Int
    let message: String?
    let data: IGPSportLoginData?
}

struct IGPSportLoginData: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let userId: String?
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case userId = "user_id"
    }
}

// MARK: - Activity Models

struct IGPSportActivityListResponse: Codable {
    let code: Int
    let message: String?
    let data: IGPSportActivityListData?
}

struct IGPSportActivityListData: Codable {
    let rows: [IGPSportActivity]?
    let total: Int?
    let pageNo: Int?
    let pageSize: Int?
}

struct IGPSportActivity: Codable, Identifiable {
    let id: String
    let rideId: Int
    let title: String?
    let name: String?
    let startTime: String?
    let startTimeString: String?
    let distance: Double?
    let duration: Int?
    let elevationGain: Double?
    let averageSpeed: Double?
    let maxSpeed: Double?
    let averagePower: Double?
    let maxPower: Double?
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averageCadence: Int?
    let maxCadence: Int?
    let calories: Int?
    let fitOssPath: String?
    let fitUrl: String?
    let fitPath: String?
    let fitDownloadUrl: String?
    let fitOssUrl: String?
    let fit: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, rideId, title, name, distance, duration, calories
        case startTime, startTimeString
        case elevationGain = "elevation_gain"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case averagePower = "average_power"
        case maxPower = "max_power"
        case averageHeartRate = "average_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case averageCadence = "average_cadence"
        case maxCadence = "max_cadence"
        case fitOssPath, fitUrl, fitPath, fitDownloadUrl, fitOssUrl, fit
    }
    
    var displayName: String {
        return title ?? name ?? "iGPSport Activity"
    }
    
    var fitFileURL: String? {
        return fitOssPath ?? fitUrl ?? fitPath ?? fitDownloadUrl ?? fitOssUrl ?? fit
    }
    
    func toActivity() -> Activity {
        let startDate = parseStartDate()
        
        return Activity(
            name: displayName,
            startDate: startDate,
            distance: distance ?? 0,
            duration: TimeInterval(duration ?? 0),
            elevationGain: elevationGain ?? 0,
            source: .igpsport,
            igpsportRideId: rideId
        )
    }
    
    private func parseStartDate() -> Date {
        let dateString = startTime ?? startTimeString ?? ""
        
        // Try different date formats
        let formatters = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy.MM.dd HH:mm:ss"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return Date()
    }
}

struct IGPSportActivityDetailResponse: Codable {
    let code: Int
    let message: String?
    let data: IGPSportActivityDetail?
}

struct IGPSportActivityDetail: Codable {
    let rideId: Int
    let title: String?
    let name: String?
    let startTime: String?
    let distance: Double?
    let duration: Int?
    let elevationGain: Double?
    let averageSpeed: Double?
    let maxSpeed: Double?
    let averagePower: Double?
    let maxPower: Double?
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averageCadence: Int?
    let maxCadence: Int?
    let calories: Int?
    let fitOssPath: String?
    let fitUrl: String?
    let fitPath: String?
    let fitDownloadUrl: String?
    let fitOssUrl: String?
    let fit: String?
    let description: String?
    let weather: String?
    let temperature: Double?
    
    private enum CodingKeys: String, CodingKey {
        case rideId, title, name, startTime, distance, duration, calories, description, weather, temperature
        case elevationGain = "elevation_gain"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case averagePower = "average_power"
        case maxPower = "max_power"
        case averageHeartRate = "average_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case averageCadence = "average_cadence"
        case maxCadence = "max_cadence"
        case fitOssPath, fitUrl, fitPath, fitDownloadUrl, fitOssUrl, fit
    }
    
    var fitFileURL: String? {
        return fitOssPath ?? fitUrl ?? fitPath ?? fitDownloadUrl ?? fitOssUrl ?? fit
    }
}
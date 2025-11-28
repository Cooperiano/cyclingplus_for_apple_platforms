//
//  StravaModels.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation

// MARK: - Authentication Models

struct StravaCredentials: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scope: String
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

struct StravaTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let expiresIn: Int
    let scope: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case scope
    }
    
    func toCredentials() -> StravaCredentials {
        return StravaCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(expiresAt)),
            scope: scope
        )
    }
}

// MARK: - API Models

struct StravaAthlete: Codable, Identifiable {
    let id: Int
    let username: String?
    let firstname: String?
    let lastname: String?
    let city: String?
    let state: String?
    let country: String?
    let sex: String?
    let premium: Bool?
    let summit: Bool?
    let createdAt: String?
    let updatedAt: String?
    let badgeTypeId: Int?
    let weight: Double?
    let profileMedium: String?
    let profile: String?
    let friend: String?
    let follower: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, username, firstname, lastname, city, state, country, sex, premium, summit, weight, profile, friend, follower
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case badgeTypeId = "badge_type_id"
        case profileMedium = "profile_medium"
    }
    
    var displayName: String {
        if let first = firstname, let last = lastname {
            return "\(first) \(last)"
        } else if let first = firstname {
            return first
        } else if let username = username {
            return username
        } else {
            return "Strava User"
        }
    }
}

struct StravaActivity: Codable, Identifiable {
    let id: Int
    let name: String
    let distance: Double
    let movingTime: Int
    let elapsedTime: Int
    let totalElevationGain: Double
    let type: String
    let sportType: String
    let startDate: String
    let startDateLocal: String
    let timezone: String
    let utcOffset: Double
    let locationCity: String?
    let locationState: String?
    let locationCountry: String?
    let achievementCount: Int
    let kudosCount: Int
    let commentCount: Int
    let athleteCount: Int
    let photoCount: Int
    let trainer: Bool
    let commute: Bool
    let manual: Bool
    let isPrivate: Bool
    let visibility: String
    let flagged: Bool
    let gearId: String?
    let fromAcceptedTag: Bool
    let uploadId: Int?
    let averageSpeed: Double?
    let maxSpeed: Double?
    let averageCadence: Double?
    let averageWatts: Double?
    let weightedAverageWatts: Int?
    let kilojoules: Double?
    let deviceWatts: Bool?
    let hasHeartrate: Bool
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    let heartRateOptOut: Bool
    let displayHideHeartrateOption: Bool
    let elevHigh: Double?
    let elevLow: Double?
    let prCount: Int
    let totalPhotoCount: Int
    let hasKudoed: Bool
    let workoutType: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, distance, type, timezone, trainer, commute, manual, isPrivate = "private", visibility, flagged
        case movingTime = "moving_time"
        case elapsedTime = "elapsed_time"
        case totalElevationGain = "total_elevation_gain"
        case sportType = "sport_type"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
        case utcOffset = "utc_offset"
        case locationCity = "location_city"
        case locationState = "location_state"
        case locationCountry = "location_country"
        case achievementCount = "achievement_count"
        case kudosCount = "kudos_count"
        case commentCount = "comment_count"
        case athleteCount = "athlete_count"
        case photoCount = "photo_count"
        case gearId = "gear_id"
        case fromAcceptedTag = "from_accepted_tag"
        case uploadId = "upload_id"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case averageCadence = "average_cadence"
        case averageWatts = "average_watts"
        case weightedAverageWatts = "weighted_average_watts"
        case kilojoules
        case deviceWatts = "device_watts"
        case hasHeartrate = "has_heartrate"
        case averageHeartrate = "average_heartrate"
        case maxHeartrate = "max_heartrate"
        case heartRateOptOut = "heartrate_opt_out"
        case displayHideHeartrateOption = "display_hide_heartrate_option"
        case elevHigh = "elev_high"
        case elevLow = "elev_low"
        case prCount = "pr_count"
        case totalPhotoCount = "total_photo_count"
        case hasKudoed = "has_kudoed"
        case workoutType = "workout_type"
    }
    
    func toActivity() -> Activity {
        let startDate = ISO8601DateFormatter().date(from: self.startDate) ?? Date()
        
        return Activity(
            name: name,
            startDate: startDate,
            distance: distance,
            duration: TimeInterval(movingTime),
            elevationGain: totalElevationGain,
            source: .strava,
            stravaId: id
        )
    }
}

struct StravaActivityStreams: Codable {
    let time: StravaStream?
    let distance: StravaStream?
    let latlng: StravaStream?
    let altitude: StravaStream?
    let velocitySmooth: StravaStream?
    let heartrate: StravaStream?
    let cadence: StravaStream?
    let watts: StravaStream?
    let temp: StravaStream?
    let moving: StravaStream?
    let gradeSmooth: StravaStream?
    
    private enum CodingKeys: String, CodingKey {
        case time, distance, latlng, altitude, cadence, watts, temp, moving
        case velocitySmooth = "velocity_smooth"
        case heartrate
        case gradeSmooth = "grade_smooth"
    }
}

struct StravaStream: Codable {
    let data: [StreamValue]
    let seriesType: String
    let originalSize: Int
    let resolution: String
    
    private enum CodingKeys: String, CodingKey {
        case data
        case seriesType = "series_type"
        case originalSize = "original_size"
        case resolution
    }
}

enum StreamValue: Codable {
    case int(Int)
    case double(Double)
    case coordinate([Double])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let coordinateValue = try? container.decode([Double].self) {
            self = .coordinate(coordinateValue)
        } else {
            throw DecodingError.typeMismatch(StreamValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode StreamValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .coordinate(let value):
            try container.encode(value)
        }
    }
    
    var doubleValue: Double? {
        switch self {
        case .int(let value):
            return Double(value)
        case .double(let value):
            return value
        case .coordinate:
            return nil
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        case .coordinate:
            return nil
        }
    }
    
    var coordinateValue: [Double]? {
        switch self {
        case .coordinate(let value):
            return value
        default:
            return nil
        }
    }
}
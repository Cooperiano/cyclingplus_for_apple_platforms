//
//  CyclingPlusError.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation

enum CyclingPlusError: LocalizedError {
    case authenticationFailed(String)
    case networkUnavailable
    case networkPermissionDenied(String)
    case stravaAPIError(String)
    case igpsportAPIError(String)
    case fileImportError(String)
    case analysisError(String)
    case dataCorruption(String)
    case invalidFileFormat(String)
    case missingData(String)
    case calculationError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkUnavailable:
            return "Network connection is unavailable. Please check your internet connection."
        case .networkPermissionDenied(let message):
            return "Network permission denied: \(message)"
        case .stravaAPIError(let message):
            return "Strava API error: \(message)"
        case .igpsportAPIError(let message):
            return "iGPSport API error: \(message)"
        case .fileImportError(let message):
            return "File import failed: \(message)"
        case .analysisError(let message):
            return "Analysis failed: \(message)"
        case .dataCorruption(let message):
            return "Data corruption detected: \(message)"
        case .invalidFileFormat(let message):
            return "Invalid file format: \(message)"
        case .missingData(let message):
            return "Missing required data: \(message)"
        case .calculationError(let message):
            return "Calculation error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please try logging in again or check your credentials."
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .networkPermissionDenied:
            return "The app does not have permission to access the network. Please ensure the app's entitlements are properly configured with network client permissions. If using a proxy, verify your system proxy settings in System Settings → Network."
        case .stravaAPIError, .igpsportAPIError:
            return "Please try again later. If the problem persists, the service may be temporarily unavailable."
        case .fileImportError:
            return "Please check that the file is a valid GPX, TCX, or FIT file and try again."
        case .analysisError:
            return "Please try the analysis again. If the problem persists, some data may be missing or corrupted."
        case .dataCorruption:
            return "Please try re-syncing your data or contact support if the problem persists."
        case .invalidFileFormat:
            return "Please ensure the file is in GPX, TCX, or FIT format."
        case .missingData:
            return "Please ensure all required data is available before performing this operation."
        case .calculationError:
            return "Please check the input data and try again."
        }
    }
}
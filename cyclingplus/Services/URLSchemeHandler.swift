//
//  URLSchemeHandler.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class URLSchemeHandler: ObservableObject {
    @Published var lastHandledURL: URL?
    private let stravaAuthManager: StravaAuthManager
    
    init(stravaAuthManager: StravaAuthManager) {
        self.stravaAuthManager = stravaAuthManager
    }
    
    func handleURL(_ url: URL) async {
        guard let scheme = url.scheme else { return }
        
        switch scheme {
        case "cyclingplus":
            await handleCyclingPlusURL(url)
        default:
            print("Unknown URL scheme: \(scheme)")
        }
    }
    
    private func handleCyclingPlusURL(_ url: URL) async {
        guard let host = url.host else { return }
        
        switch host {
        case "auth":
            // Handle cyclingplus://auth/strava or cyclingplus://auth
            await handleAuthCallback(url)
        case "cyclingplus":
            // Handle cyclingplus://cyclingplus (alternative format)
            await handleAuthCallback(url)
        default:
            print("Unknown CyclingPlus URL host: \(host)")
        }
    }
    
    private func handleAuthCallback(_ url: URL) async {
        do {
            try await stravaAuthManager.handleAuthorizationCallback(url: url)
        } catch {
            print("Authentication callback error: \(error)")
        }
    }
}
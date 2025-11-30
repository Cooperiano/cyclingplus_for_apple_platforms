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
        print("🔗 URLSchemeHandler received URL: \(url.absoluteString)")
        
        guard let scheme = url.scheme else {
            print("❌ No URL scheme found")
            return
        }
        
        print("✅ URL scheme: \(scheme)")
        
        switch scheme {
        case "cyclingplus":
            await handleCyclingPlusURL(url)
        default:
            print("❌ Unknown URL scheme: \(scheme)")
        }
    }
    
    private func handleCyclingPlusURL(_ url: URL) async {
        print("🔍 Parsing CyclingPlus URL...")
        print("   Host: \(url.host ?? "nil")")
        print("   Path: \(url.path)")
        print("   Query: \(url.query ?? "nil")")
        
        guard let host = url.host else {
            print("❌ No host found in URL")
            return
        }
        
        switch host {
        case "auth":
            // Handle cyclingplus://auth/strava or cyclingplus://auth
            print("✅ Handling auth callback")
            await handleAuthCallback(url)
        case "strava":
            // Handle cyclingplus://strava (Strava OAuth callback)
            print("✅ Handling Strava OAuth callback")
            await handleAuthCallback(url)
        case "cyclingplus":
            // Handle cyclingplus://cyclingplus (alternative format)
            print("✅ Handling alternative auth callback")
            await handleAuthCallback(url)
        default:
            print("❌ Unknown CyclingPlus URL host: \(host)")
        }
    }
    
    private func handleAuthCallback(_ url: URL) async {
        print("🔐 Processing auth callback...")
        do {
            try await stravaAuthManager.handleAuthorizationCallback(url: url)
            print("✅ Authentication successful!")
        } catch {
            print("❌ Authentication callback error: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }
}
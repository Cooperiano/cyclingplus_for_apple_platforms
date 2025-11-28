//
//  DataFreshnessIndicator.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct DataFreshnessIndicator: View {
    let lastSyncDate: Date?
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        #if os(macOS)
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        if !isOnline {
            return .orange
        }
        
        guard let lastSync = lastSyncDate else {
            return .gray
        }
        
        let hoursSinceSync = Date().timeIntervalSince(lastSync) / 3600
        
        if hoursSinceSync < 1 {
            return .green
        } else if hoursSinceSync < 24 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    private var statusText: String {
        if !isOnline {
            return "Offline"
        }
        
        guard let lastSync = lastSyncDate else {
            return "Never synced"
        }
        
        let hoursSinceSync = Date().timeIntervalSince(lastSync) / 3600
        
        if hoursSinceSync < 1 {
            let minutes = Int(Date().timeIntervalSince(lastSync) / 60)
            return "Synced \(minutes)m ago"
        } else if hoursSinceSync < 24 {
            let hours = Int(hoursSinceSync)
            return "Synced \(hours)h ago"
        } else {
            let days = Int(hoursSinceSync / 24)
            return "Synced \(days)d ago"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DataFreshnessIndicator(lastSyncDate: Date(), isOnline: true)
        DataFreshnessIndicator(lastSyncDate: Date().addingTimeInterval(-3600), isOnline: true)
        DataFreshnessIndicator(lastSyncDate: Date().addingTimeInterval(-86400), isOnline: true)
        DataFreshnessIndicator(lastSyncDate: nil, isOnline: false)
    }
    .padding()
}

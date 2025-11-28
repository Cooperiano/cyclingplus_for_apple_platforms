//
//  LoadingOverlay.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct LoadingOverlay: View {
    let message: String?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)
                
                if let message = message {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    #if os(macOS)
                    #if os(macOS)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    #else
                    .fill(Color(.systemBackground))
                    #endif
                    #else
                    .fill(Color(.systemBackground))
                    #endif
                    .shadow(radius: 20)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    LoadingOverlay(message: "Syncing activities...")
}

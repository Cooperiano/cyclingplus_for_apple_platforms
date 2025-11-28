//
//  ToastView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct ToastView: View {
    let message: ToastMessage
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.type.icon)
                .font(.title3)
                .foregroundColor(message.type.color)
            
            Text(message.message)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                #if os(macOS)
                #if os(macOS)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    #else
                    .fill(Color(.systemBackground))
                    #endif
                #else
                .fill(Color(.systemBackground))
                #endif
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ToastView(message: ToastMessage(message: "Activity synced successfully", type: .success))
        ToastView(message: ToastMessage(message: "Connection lost", type: .warning))
        ToastView(message: ToastMessage(message: "Failed to load data", type: .error))
        ToastView(message: ToastMessage(message: "Processing activity...", type: .info))
    }
    .padding()
}

//
//  AppStateOverlay.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct AppStateOverlay: ViewModifier {
    @ObservedObject var appState: AppStateManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Loading overlay
            if appState.isLoading {
                LoadingOverlay(message: appState.loadingMessage)
            }
            
            // Toast messages
            VStack {
                if let toast = appState.toastMessage {
                    ToastView(message: toast)
                        .padding(.top, 16)
                }
                Spacer()
            }
            .animation(.spring(), value: appState.toastMessage?.id)
        }
        .errorAlert(appState: appState)
    }
}

extension View {
    func appStateOverlay(_ appState: AppStateManager) -> some View {
        modifier(AppStateOverlay(appState: appState))
    }
}

// MARK: - Preview

#Preview {
    let appState = AppStateManager()
    
    return VStack {
        Button("Show Loading") {
            appState.startLoading("Loading data...")
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                appState.stopLoading()
            }
        }
        
        Button("Show Success Toast") {
            appState.showSuccess("Operation completed successfully")
        }
        
        Button("Show Error") {
            appState.handleError(
                AppError(
                    title: "Sync Failed",
                    message: "Unable to sync activities from Strava",
                    context: "Network connection lost",
                    recoveryOptions: [
                        RecoveryOption(title: "Retry") {
                            print("Retrying...")
                        }
                    ]
                )
            )
        }
    }
    .frame(width: 400, height: 300)
    .appStateOverlay(appState)
}

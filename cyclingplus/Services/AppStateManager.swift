//
//  AppStateManager.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import SwiftUI
import Combine

/// Global app state manager for error handling and loading states
@MainActor
class AppStateManager: ObservableObject {
    @Published var isLoading = false
    @Published var loadingMessage: String?
    @Published var currentError: AppError?
    @Published var showError = false
    @Published var toastMessage: ToastMessage?
    
    // MARK: - Loading State
    
    func startLoading(_ message: String) {
        isLoading = true
        loadingMessage = message
    }
    
    func stopLoading() {
        isLoading = false
        loadingMessage = nil
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error, context: String? = nil) {
        let appError = AppError(
            title: "Error",
            message: error.localizedDescription,
            context: context,
            underlyingError: error
        )
        currentError = appError
        showError = true
    }
    
    func handleError(_ appError: AppError) {
        currentError = appError
        showError = true
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
    
    // MARK: - Toast Messages
    
    func showToast(_ message: String, type: ToastType = .info) {
        toastMessage = ToastMessage(message: message, type: type)
        
        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if toastMessage?.message == message {
                toastMessage = nil
            }
        }
    }
    
    func showSuccess(_ message: String) {
        showToast(message, type: .success)
    }
    
    func showWarning(_ message: String) {
        showToast(message, type: .warning)
    }
    
    func showInfo(_ message: String) {
        showToast(message, type: .info)
    }
}

// MARK: - Supporting Types

struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let context: String?
    let underlyingError: Error?
    let recoveryOptions: [RecoveryOption]
    
    init(
        title: String,
        message: String,
        context: String? = nil,
        underlyingError: Error? = nil,
        recoveryOptions: [RecoveryOption] = []
    ) {
        self.title = title
        self.message = message
        self.context = context
        self.underlyingError = underlyingError
        self.recoveryOptions = recoveryOptions
    }
}

struct RecoveryOption {
    let title: String
    let action: () -> Void
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
}

enum ToastType {
    case success
    case warning
    case error
    case info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

//
//  ErrorAlertView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var appState: AppStateManager
    
    func body(content: Content) -> some View {
        content
            .alert(
                appState.currentError?.title ?? "Error",
                isPresented: $appState.showError,
                presenting: appState.currentError
            ) { error in
                if !error.recoveryOptions.isEmpty {
                    ForEach(error.recoveryOptions.indices, id: \.self) { index in
                        Button(error.recoveryOptions[index].title) {
                            error.recoveryOptions[index].action()
                            appState.clearError()
                        }
                    }
                }
                
                Button("OK", role: .cancel) {
                    appState.clearError()
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.message)
                    
                    if let context = error.context {
                        Text("Context: \(context)")
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(appState: AppStateManager) -> some View {
        modifier(ErrorAlertModifier(appState: appState))
    }
}

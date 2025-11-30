//
//  UIStyle.swift
//  cyclingplus
//
//  Created by Codex on 2025/11/30.
//

import SwiftUI

struct CardStyle: ViewModifier {
    var padding: CGFloat = 12
    var cornerRadius: CGFloat = 12
    
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(.secondarySystemBackground)
        #endif
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 12, cornerRadius: CGFloat = 12) -> some View {
        self.modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}

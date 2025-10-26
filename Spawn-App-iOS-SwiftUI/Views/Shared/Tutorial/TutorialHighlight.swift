//
//  TutorialHighlight.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import SwiftUI

/// A modifier to apply tutorial highlighting to specific views
struct TutorialHighlight: ViewModifier {
    let isHighlighted: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isHighlighted ? Color.white : Color.clear,
                        lineWidth: isHighlighted ? 3 : 0
                    )
                    .animation(.easeInOut(duration: 0.3), value: isHighlighted)
            )
            .shadow(
                color: isHighlighted ? Color.white.opacity(0.6) : Color.clear,
                radius: isHighlighted ? 12 : 0
            )
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isHighlighted)
    }
}

extension View {
    /// Apply tutorial highlighting to a view
    func tutorialHighlight(isHighlighted: Bool, cornerRadius: CGFloat = 12) -> some View {
        self.modifier(TutorialHighlight(isHighlighted: isHighlighted, cornerRadius: cornerRadius))
    }
}


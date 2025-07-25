//
//  TutorialOverlayView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import SwiftUI

struct TutorialOverlayView: View {
    @ObservedObject var tutorialViewModel = TutorialViewModel.shared
    @Environment(\.colorScheme) var colorScheme
    
    let activityTypesFrame: CGRect?
    let headerFrame: CGRect?
    
    @State private var showCallout = false
    
    init(activityTypesFrame: CGRect? = nil, headerFrame: CGRect? = nil) {
        self.activityTypesFrame = activityTypesFrame
        self.headerFrame = headerFrame
    }
    
    var body: some View {
        ZStack {
            if tutorialViewModel.tutorialState.shouldShowTutorialOverlay {
                // Semi-transparent background overlay
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent background taps during tutorial
                    }
                
                // Tutorial callout
                if showCallout && tutorialViewModel.shouldShowCallout {
                    tutorialCallout
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .onAppear {
            if tutorialViewModel.tutorialState.shouldShowTutorialOverlay {
                // Animate in the callout with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showCallout = true
                    }
                }
            }
        }
        .onChange(of: tutorialViewModel.tutorialState) { newState in
            if !newState.shouldShowTutorialOverlay {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCallout = false
                }
            }
        }
    }
    
    private var tutorialCallout: some View {
        VStack(spacing: 16) {
            // Callout text
            VStack(spacing: 8) {
                Text("Welcome to Spawn! 👋")
                    .font(.onestSemiBold(size: 20))
                    .foregroundColor(.white)
                
                Text("Tap on an Activity Type to create your first activity")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            
            // Arrow pointing down to activity types
            Image(systemName: "arrow.down")
                .font(.title2)
                .foregroundColor(.white)
                .opacity(0.8)
        }
        .position(x: UIScreen.main.bounds.width / 2, y: calculateCalloutPosition())
    }
    
    private func calculateCalloutPosition() -> CGFloat {
        // Position the callout above the activity types
        if let activityTypesFrame = activityTypesFrame {
            return activityTypesFrame.minY - 120
        } else {
            // Default position
            return UIScreen.main.bounds.height * 0.3
        }
    }
}

/// A modifier to apply tutorial highlighting to specific views
struct TutorialHighlight: ViewModifier {
    let isHighlighted: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isHighlighted ? Color.white.opacity(0.8) : Color.clear,
                        lineWidth: isHighlighted ? 2 : 0
                    )
                    .shadow(
                        color: isHighlighted ? Color.white.opacity(0.5) : Color.clear,
                        radius: isHighlighted ? 8 : 0
                    )
            )
            .scaleEffect(isHighlighted ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isHighlighted)
    }
}

extension View {
    /// Apply tutorial highlighting to a view
    func tutorialHighlight(isHighlighted: Bool, cornerRadius: CGFloat = 12) -> some View {
        self.modifier(TutorialHighlight(isHighlighted: isHighlighted, cornerRadius: cornerRadius))
    }
} 
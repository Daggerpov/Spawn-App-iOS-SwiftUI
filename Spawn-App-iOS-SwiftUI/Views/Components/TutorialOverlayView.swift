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
                // Semi-transparent background overlay with cutout for activity types
                VStack(spacing: 0) {
                    // Top overlay (above activity types)
                    Color.black.opacity(0.6)
                        .frame(height: 160) // Cover header and "Spawn in!" section
//						.cornerRadius(16)

                    // Clear space for activity types (roughly 115px height + padding)
					RoundedRectangle(cornerRadius: 16)
						.fill(Color.clear)
                        .frame(height: 10)
						.padding()

                    // Clear space for welcome message (roughly 80px height + padding)
                    Color.clear
                        .frame(height: 100)
						.cornerRadius(16)

                    // Bottom overlay (below welcome message)
                    Color.black.opacity(0.6)
                        .frame(maxHeight: .infinity)
                }
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
        VStack(spacing: 12) {
            // Callout text with theme-appropriate styling
            VStack(spacing: 8) {
                Text("Welcome to Spawn! 👋")
                    .font(.onestSemiBold(size: 18))
                    .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                
                Text("Tap on an Activity Type to create your first activity")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .padding(.horizontal, 32)
        }
        .position(x: UIScreen.main.bounds.width / 2, y: calculateCalloutPosition())
    }
    
    private func calculateCalloutPosition() -> CGFloat {
        // Position the callout in the space between activity types and "See what's happening"
        // Activity types end around 425px, "See what's happening" starts around 500px
        // So position callout around 450px from top
        return 350
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

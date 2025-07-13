//
//  TutorialFocusOverlay.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import SwiftUI

/// A view that creates a focus overlay effect, highlighting specific areas while dimming the rest
struct TutorialFocusOverlay: View {
    let focusedElements: [FocusedElement]
    let tutorialMessage: String
    let onTapAnywhereToContinue: Bool
    let onContinue: () -> Void
    
    init(
        focusedElements: [FocusedElement],
        tutorialMessage: String,
        onTapAnywhereToContinue: Bool = false,
        onContinue: @escaping () -> Void
    ) {
        self.focusedElements = focusedElements
        self.tutorialMessage = tutorialMessage
        self.onTapAnywhereToContinue = onTapAnywhereToContinue
        self.onContinue = onContinue
    }
    
    var body: some View {
        ZStack {
            // Dark overlay covering the entire screen
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    if onTapAnywhereToContinue {
                        onContinue()
                    }
                }
            
            // Clear holes for focused elements
            ForEach(focusedElements.indices, id: \.self) { index in
                let element = focusedElements[index]
                
                // Create a clear hole for the focused element
                RoundedRectangle(cornerRadius: element.cornerRadius)
                    .frame(width: element.size.width, height: element.size.height)
                    .position(element.position)
                    .blendMode(.destinationOut)
            }
            
            // Tutorial message box
            tutorialMessageView
        }
        .compositingGroup()
        .allowsHitTesting(true)
    }
    
    private var tutorialMessageView: some View {
        VStack(spacing: 15) {
            Text(tutorialMessage)
                .font(Font.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            if onTapAnywhereToContinue {
                Text("*Tap anywhere to continue*")
                    .font(Font.custom("Onest", size: 16).weight(.semibold))
                    .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .frame(width: 380)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.25), radius: 4, y: 3)
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.85)
    }
}

/// Represents an element that should be highlighted in the tutorial
struct FocusedElement {
    let position: CGPoint
    let size: CGSize
    let cornerRadius: CGFloat
    
    init(position: CGPoint, size: CGSize, cornerRadius: CGFloat = 12) {
        self.position = position
        self.size = size
        self.cornerRadius = cornerRadius
    }
}

/// A view modifier that makes an element focusable in the tutorial
struct TutorialFocusable: ViewModifier {
    let isFocused: Bool
    let onTapped: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .opacity(isFocused ? 1.0 : 0.3)
            .onTapGesture {
                if isFocused {
                    onTapped?()
                }
            }
            .allowsHitTesting(isFocused)
    }
}

extension View {
    /// Makes this view focusable in the tutorial system
    func tutorialFocusable(isFocused: Bool, onTapped: (() -> Void)? = nil) -> some View {
        self.modifier(TutorialFocusable(isFocused: isFocused, onTapped: onTapped))
    }
}

/// A specialized tutorial overlay for the feed view activity types
struct TutorialFeedActivityTypesOverlay: View {
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    let activityTypes: [ActivityTypeDTO]
    let onActivityTypeSelected: (ActivityTypeDTO) -> Void
    
    var body: some View {
        if tutorialViewModel.isInTutorial && tutorialViewModel.currentStep == .feedViewActivityTypes {
            ZStack {
                // Dark overlay
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                // Tutorial message
                VStack(spacing: 15) {
                    Text(tutorialViewModel.currentStep.title)
                        .font(Font.custom("Onest", size: 16).weight(.medium))
                        .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                        .multilineTextAlignment(.center)
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .frame(width: 380, height: 100)
                .background(.white)
                .cornerRadius(16)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.85)
            }
            .allowsHitTesting(false)
        }
    }
}

/// A specialized tutorial overlay for the people management intro
struct TutorialPeopleIntroOverlay: View {
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    let onContinue: () -> Void
    
    var body: some View {
        if tutorialViewModel.isInTutorial && tutorialViewModel.currentStep == .activityCreationPeopleIntro {
            ZStack {
                // Dark overlay
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onContinue()
                    }
                
                // Tutorial message
                VStack(spacing: 15) {
                    Text(tutorialViewModel.currentStep.title)
                        .font(Font.custom("Onest", size: 24).weight(.medium))
                        .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                        .multilineTextAlignment(.center)
                        .offset(y: 0.5)
                    
                    Text("*Tap anywhere to continue*")
                        .font(Font.custom("Onest", size: 16).weight(.semibold))
                        .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                        .offset(y: 209)
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .frame(width: 380, height: 469)
                .background(.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.25), radius: 4, y: 3)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.52)
            }
            .allowsHitTesting(true)
        }
    }
}

/// A specialized tutorial overlay for the "Next Step" button focus
struct TutorialNextStepFocusOverlay: View {
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    let isEnabled: Bool
    let onNextStep: () -> Void
    
    var body: some View {
        if tutorialViewModel.isInTutorial && 
           (tutorialViewModel.currentStep == .activityCreationPeopleManagement ||
            tutorialViewModel.currentStep == .activityCreationDateTime ||
            tutorialViewModel.currentStep == .activityCreationLocation) {
            
            ZStack {
                // Dark overlay
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                // Clear hole for the Next Step button
                RoundedRectangle(cornerRadius: 16)
                    .frame(width: 375, height: 56)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.75)
                    .blendMode(.destinationOut)
                
                // Tutorial message
                VStack(spacing: 15) {
                    Text(tutorialViewModel.currentStep.title)
                        .font(Font.custom("Onest", size: 16).weight(.medium))
                        .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                        .multilineTextAlignment(.center)
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .frame(width: 380, height: 100)
                .background(.white)
                .cornerRadius(16)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.85)
            }
            .compositingGroup()
            .allowsHitTesting(false)
        }
    }
} 
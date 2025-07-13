//
//  SpawnInfoView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct OnboardingPage {
    let imageName: String
    let title: String
    let description: String
}

struct SpawnIntroView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    let pages = [
        OnboardingPage(
            imageName: "Group 6812",
            title: "Stay in the Loop",
            description: "Know what your friends are up to—so you can jump in or start something new."
        ),
        OnboardingPage(
            imageName: "Group 6813",
            title: "Set the Vibe",
            description: "Quick-start your plans with activity presets — or make one \nthat fits you."
        ),
        OnboardingPage(
            imageName: "Group 6814",
            title: "What's Happening Near You",
            description: "Easily spot nearby hangouts, meetups, or last-minute plans worth joining."
        )
    ]
    
    private func getImageName(for pageIndex: Int) -> String {
        // Use dark mode assets when in dark mode
        if colorScheme == .dark {
            switch pageIndex {
            case 0: // "Stay in the Loop" page
                return "onboarding_activity_cards_dark_mode"
            case 1: // "Set the Vibe" page
                return "onboarding_activity_types_dark_mode"
            default:
                return pages[pageIndex].imageName
            }
        }
        return pages[pageIndex].imageName
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
                .padding(.leading, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            
            Spacer()
            
            // Main content
            VStack(spacing: 32) {
                // Image
                Image(getImageName(for: currentPage))
                    .resizable()
                    .scaledToFit()
					.frame(maxWidth: .infinity, maxHeight: 320)
                    .padding(.horizontal, 20)
                    .scaleEffect(currentPage == 0 ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(pages[currentPage].title)
                        .font(heading1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                    
                    Text(pages[currentPage].description)
                        .font(body1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
                
                // Custom Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        if index == currentPage {
                            Capsule()
                                .fill(figmaIndigo)
                                .frame(width: 20, height: 6)
                        } else {
                            Circle()
                                .fill(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .padding(.bottom, 20)
                
                // Next Button
                if currentPage == pages.count - 1 {
                    OnboardingButtonView("Next", destination: SignInView())
                } else {
                    SpawnIntroButtonView("Next") {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        }
                    }
                }
            }
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .navigationBarHidden(true)
    }
}

#Preview {
    SpawnIntroView()
}

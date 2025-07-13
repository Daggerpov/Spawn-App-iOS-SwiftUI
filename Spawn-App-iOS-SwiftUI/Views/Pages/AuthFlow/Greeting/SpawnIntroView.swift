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
    
    let pages = [
        OnboardingPage(
            imageName: "Group 6812",
            title: "Stay in the Loop",
            description: "Know what your friends are up to—so you can jump in or start something new."
        ),
        OnboardingPage(
            imageName: "Group 6820",
            title: "Set the Vibe",
            description: "Quick-start your plans with activity presets — or make one \nthat fits you."
        ),
        OnboardingPage(
            imageName: "Group 6821",
            title: "What’s Happening Near You",
            description: "Easily spot nearby hangouts, meetups, or last-minute plans worth joining."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            
            // Logo
            Image("SpawnLogo")
                .padding(.top, 10)
                .padding(.bottom, 40)
            
            // Image Carousel
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 20) {
                        Image(page.imageName)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 260)
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            
            Spacer()
            
            // Bottom Content
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(pages[currentPage].title)
                        .font(heading1)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                    
                    Text(pages[currentPage].description)
                        .font(body1)
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
                                .fill(Color.gray.opacity(0.3))
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
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }
}

struct SpawnOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        SpawnIntroView()
            .preferredColorScheme(.light)
        
        SpawnIntroView()
            .preferredColorScheme(.dark)
    }
}

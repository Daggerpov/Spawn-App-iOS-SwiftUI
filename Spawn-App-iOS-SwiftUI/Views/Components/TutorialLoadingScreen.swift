//
//  TutorialLoadingScreen.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import SwiftUI

/// A loading screen that shows while waiting for activity types to load
struct TutorialLoadingScreen: View {
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    @State private var animationTimer: Timer?
    
    let onLoadingComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Logo
                Image("spawn_branding_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                // Loading message
                VStack(spacing: 16) {
                    Text("Getting things ready...")
                        .font(Font.custom("Onest", size: 24).weight(.semibold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    
                    if tutorialViewModel.shouldShowTutorialForNewUser() {
                        Text("We're preparing your first activity creation experience")
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Loading activity types...")
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                    }
                }
                
                // Progress bar
                ProgressView(value: loadingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.42, green: 0.51, blue: 0.98)))
                    .frame(width: 200)
                    .scaleEffect(y: 2)
                
                // Loading dots animation
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(red: 0.42, green: 0.51, blue: 0.98))
                            .frame(width: 8, height: 8)
                            .scaleEffect(loadingProgress > Double(index) * 0.33 ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: loadingProgress
                            )
                    }
                }
            }
        }
        .onAppear {
            startLoadingAnimation()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func startLoadingAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                loadingProgress += 0.02
                
                if loadingProgress >= 1.0 {
                    animationTimer?.invalidate()
                    
                    // Add a small delay before completing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onLoadingComplete()
                    }
                }
            }
        }
    }
}

/// A view that manages the loading state and transitions to the feed view
struct TutorialAwareFeedLoader: View {
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    @StateObject private var feedViewModel: FeedViewModel
    @State private var isLoadingComplete = false
    @State private var showLoadingScreen = true
    
    let user: BaseUserDTO
    let onLoadingComplete: () -> Void
    
    init(user: BaseUserDTO, onLoadingComplete: @escaping () -> Void) {
        self.user = user
        self.onLoadingComplete = onLoadingComplete
        _feedViewModel = StateObject(
            wrappedValue: FeedViewModel(
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService(),
                userId: user.id
            )
        )
    }
    
    var body: some View {
        ZStack {
            if showLoadingScreen {
                TutorialLoadingScreen {
                    handleLoadingComplete()
                }
            } else {
                // The actual feed content will be shown by the parent view
                Color.clear
            }
        }
        .onAppear {
            loadActivityTypes()
        }
    }
    
    private func loadActivityTypes() {
        Task {
            // Fetch activity types
            await feedViewModel.fetchAllData()
            
            // Check if we have activity types loaded
            if !feedViewModel.sortedActivityTypes.isEmpty {
                tutorialViewModel.enableUIInteraction()
                isLoadingComplete = true
            } else {
                // If no activity types, wait a bit and try again
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await loadActivityTypes()
            }
        }
    }
    
    private func handleLoadingComplete() {
        showLoadingScreen = false
        onLoadingComplete()
    }
}

/// A view modifier that adds loading screen functionality to the feed view
struct TutorialLoadingModifier: ViewModifier {
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    @State private var shouldShowLoadingScreen = false
    
    let user: BaseUserDTO
    
    func body(content: Content) -> some View {
        ZStack {
            if shouldShowLoadingScreen {
                TutorialAwareFeedLoader(user: user) {
                    shouldShowLoadingScreen = false
                }
            } else {
                content
            }
        }
        .onAppear {
            // Show loading screen for new users or when activity types need to be loaded
            if tutorialViewModel.shouldShowTutorialForNewUser() || !tutorialViewModel.isActivityTypesLoaded {
                shouldShowLoadingScreen = true
            }
        }
    }
}

extension View {
    /// Adds tutorial-aware loading screen functionality
    func withTutorialLoading(user: BaseUserDTO) -> some View {
        self.modifier(TutorialLoadingModifier(user: user))
    }
} 
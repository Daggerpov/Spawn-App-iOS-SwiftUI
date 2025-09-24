//
//  RiveAnimationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2024-12-30.
//

import SwiftUI
import RiveRuntime

struct RiveAnimationView: View {
    let fileName: String
    let animationName: String?
    let autoPlay: Bool
    let loop: Bool
    let fit: RiveFit
    let alignment: RiveAlignment
    
    @State private var riveViewModel: RiveViewModel?
    @State private var loadingFailed = false
    
    init(
        fileName: String,
        animationName: String? = nil,
        autoPlay: Bool = true,
        loop: Bool = true,
        fit: RiveFit = .contain,
        alignment: RiveAlignment = .center
    ) {
        self.fileName = fileName
        self.animationName = animationName
        self.autoPlay = autoPlay
        self.loop = loop
        self.fit = fit
        self.alignment = alignment
    }
    
    var body: some View {
        Group {
            if let viewModel = riveViewModel, !loadingFailed {
                viewModel.view()
                    .aspectRatio(contentMode: .fit)
            } else if loadingFailed {
                // Fallback when Rive fails to load
                Image("spawn_branding_logo")
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback while loading
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            setupRiveViewModel()
        }
    }
    
    private func setupRiveViewModel() {
        // Initialize Rive view model
        riveViewModel = RiveViewModel(
            fileName: fileName,
            fit: fit,
            alignment: alignment,
            autoPlay: autoPlay
        )
        
        // Check if the view model was created successfully
        guard let viewModel = riveViewModel else {
            print("Failed to load Rive animation: \(fileName)")
            loadingFailed = true
            return
        }
        
        // If specific animation name is provided, play it
        if let animationName = animationName {
            viewModel.play(animationName: animationName)
        }
        
        // Add a timeout to detect if Rive fails to load properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // If after 1 second the view model still hasn't loaded properly, show fallback
            if self.riveViewModel == nil {
                self.loadingFailed = true
            }
        }
    }
}

// MARK: - Convenience Initializers for Spawn App

extension RiveAnimationView {
    /// Initializer for loading animation - optimized for app launch
    static func loadingAnimation(fileName: String) -> RiveAnimationView {
        return RiveAnimationView(
            fileName: fileName,
            animationName: nil,
            autoPlay: true,
            loop: true,
            fit: .contain,
            alignment: .center
        )
    }
    
    /// Initializer for logo animation - optimized for branding
    static func logoAnimation(fileName: String) -> RiveAnimationView {
        return RiveAnimationView(
            fileName: fileName,
            animationName: nil,
            autoPlay: true,
            loop: false,
            fit: .contain,
            alignment: .center
        )
    }
}

#Preview {
    RiveAnimationView.loadingAnimation(fileName: "spawn_logo_animation")
        .frame(width: 300, height: 300)
        .background(Color.white)
} 

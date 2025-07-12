//
//  LoadingView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by AI Assistant on 2024-08-02.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            
            // Rive animation - falls back to static logo if .riv file not found
            RiveAnimationView.loadingAnimation(fileName: "spawn_logo_animation")
                .frame(width: 200, height: 200)
                .background(
                    // Fallback to static logo if Rive fails
                    Image("spawn_branding_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 100)
                        .opacity(0) // Hidden when Rive is working
                )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // Changed from authPageBackgroundColor to white
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
} 
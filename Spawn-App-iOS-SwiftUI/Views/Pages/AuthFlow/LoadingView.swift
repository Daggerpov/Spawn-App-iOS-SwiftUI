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
                .frame(width: 300, height: 300)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // White background to match animation
        .ignoresSafeArea(.all) // Ignore all safe areas including top and bottom
        .preferredColorScheme(.light) // Force light mode to ensure white background
    }
}

#Preview {
    LoadingView()
} 

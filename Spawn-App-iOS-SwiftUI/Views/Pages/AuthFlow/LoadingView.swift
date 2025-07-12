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
            
            Image("spawn_branding_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 100)
            
            Spacer().frame(height: 24)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(authPageBackgroundColor)
        .ignoresSafeArea()
    }
}

#Preview {
    LoadingView()
} 
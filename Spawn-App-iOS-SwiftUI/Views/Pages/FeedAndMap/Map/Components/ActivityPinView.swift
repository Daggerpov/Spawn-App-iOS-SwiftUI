//
//  ActivityPinView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//
import SwiftUI

struct ActivityPinView: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            // Pin background with drop shadow
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            
            // Activity icon
            Text(icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
    }
}


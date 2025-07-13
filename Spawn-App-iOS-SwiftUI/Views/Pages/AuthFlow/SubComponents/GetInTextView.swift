//
//  GetInTextView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct GetInTextView: View {
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Let's Get You In")
                .font(heading1)
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                .multilineTextAlignment(.center)
            
            Text("Join your friends or start a hang. It's all happening here.")
                .font(body1)
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }
}

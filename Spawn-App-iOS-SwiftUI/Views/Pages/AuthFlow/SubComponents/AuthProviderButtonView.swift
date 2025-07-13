//
//  AuthProviderButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct AuthProviderButtonView: View {
	var authProviderType: AuthProviderType
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Animation states
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    init(_ type: AuthProviderType) {
        self.authProviderType = type
    }
    
    init(authProviderType: AuthProviderType) {
        self.authProviderType = authProviderType
    }

	var body: some View {
		HStack {
			switch authProviderType {
			case .apple:
				Image(systemName: "applelogo")
					.font(.onestMedium(size: 20))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
			case .google:
				Image("google_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 25, height: 25)
                case .email:
                    EmptyView()
			}

			Text(
				"Continue with \(authProviderType == .google ? "Google" : "Apple")"
			)
			.font(.onestMedium(size: 16))
            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
		}
		.padding()
		.frame(maxWidth: .infinity)
		.cornerRadius(16)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(getButtonBackgroundColor())
		)
        .scaleEffect(scale)
        .shadow(
            color: Color.black.opacity(0.15),
            radius: isPressed ? 2 : 8,
            x: 0,
            y: isPressed ? 2 : 4
        )
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
            scale = pressing ? 0.95 : 1.0
            
            // Haptic feedback on press
            if pressing {
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
            }
        }, perform: {})
	}
    
    private func getButtonBackgroundColor() -> Color {
        let currentScheme = themeService.colorScheme
        switch currentScheme {
        case .light:
            return figmaAuthButtonGrey
        case .dark:
            return Color(hex: "#2C2C2C")
        case .system:
            return colorScheme == .dark ? Color(hex: "#2C2C2C") : figmaAuthButtonGrey
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	AuthProviderButtonView(authProviderType: AuthProviderType.google).environmentObject(appCache)
}

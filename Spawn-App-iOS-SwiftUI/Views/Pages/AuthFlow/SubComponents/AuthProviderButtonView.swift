//
//  AuthProviderButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct AuthProviderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AuthProviderButtonView: View {
	var authProviderType: AuthProviderType
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
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
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
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

//
//  AuthProviderButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct AuthProviderButtonView: View {
	var authProviderType: AuthProviderType

	var body: some View {
		HStack {
			switch authProviderType {
				case .apple:
					Image(systemName: "applelogo")
						.font(.system(size: 20))
				case .google:
					Image("google_logo")
						.resizable()
						.scaledToFit()
						.frame(width: 25, height: 25)
			}

			Text("Continue with \(authProviderType == .google ? "Google" : "Apple")")
				.fontWeight(.medium)
		}
		.padding()
		.frame(maxWidth: .infinity)
		.cornerRadius(8)
		.foregroundColor(.black)
//		.overlay(
//			RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
//				.stroke(universalAccentColor, lineWidth: 2)
//		)
		.background(
			RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
				.fill(.white)
		)
		.padding(.horizontal, 32)
	}
}

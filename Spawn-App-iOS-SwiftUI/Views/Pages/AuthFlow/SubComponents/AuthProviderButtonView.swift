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
					.font(.onestMedium(size: 20))
			case .google:
				Image("google_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 25, height: 25)
			}

			Text(
				"Continue with \(authProviderType == .google ? "Google" : "Apple")"
			)
			.font(.onestMedium(size: 16))
		}
		.padding()
		.frame(maxWidth: .infinity)
		.cornerRadius(8)
		.foregroundColor(.black)
		.background(
			RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
				.fill(.white)
		)
		.padding(.horizontal, 32)
	}

}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	AuthProviderButtonView(authProviderType: AuthProviderType.google).environmentObject(appCache)
}

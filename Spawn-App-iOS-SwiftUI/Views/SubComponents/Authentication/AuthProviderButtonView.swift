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
			Image(systemName: authProviderType == .google ? "g.circle" : "applelogo")
				.font(.system(size: 20))
			Text("Continue with \(authProviderType == .google ? "Google" : "Apple")")
				.fontWeight(.medium)
		}
		.padding()
		.frame(maxWidth: .infinity)
		.background(Color.white)
		.cornerRadius(8)
		.foregroundColor(.black)
		.padding(.horizontal, 32)
	}
}

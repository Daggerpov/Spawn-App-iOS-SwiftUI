//
//  OnboardingButtonCoreView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct OnboardingButtonCoreView: View {
	let buttonText: String
	var fill: () -> Color = { return figmaIndigo }

	init(_ buttonText: String) {
		self.buttonText = buttonText
	}

	init(_ buttonText: String, fill: @escaping () -> Color) {
		self.buttonText = buttonText
		self.fill = fill
	}

	var body: some View {
		HStack {
			Spacer()
			Text(buttonText)
				.font(.onestSemiBold(size: 20))
				.foregroundColor(.white)
				.lineLimit(1)
				.truncationMode(.tail)
				.allowsTightening(true)
				.padding(.vertical, 16)
				.padding(.horizontal, 22)
			Spacer()
		}
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(fill())
		)
		.padding(.horizontal, 12)
		.padding(.vertical, 32)
		.frame(maxWidth: .infinity)
		.shadow(
			color: Color.black.opacity(0.15),
			radius: 8,
			x: 0,
			y: 4
		)
	}
}

#Preview {
	OnboardingButtonCoreView("Sign in with username or email")
}

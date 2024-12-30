//
//  LaunchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct LaunchView: View {
	var body: some View {
		VStack {
			Spacer()

			Image("spawn_launch_logo")
				.resizable()
				.scaledToFit()
				.frame(width: 100, height: 100)

			Text("spawn")
				.font(.system(size: 40, weight: .bold))
				.foregroundColor(.white)
				.padding(.top, 8)

			Text("Spontaneity made easy.")
				.font(.system(size: 16))
				.foregroundColor(.white)
				.padding(.top, 8)

			Spacer()

			Button(action: {}) {
				HStack {
					Image(systemName: "g.circle")
						.font(.system(size: 20))
					Text("Continue with Google")
						.fontWeight(.medium)
				}
				.padding()
				.frame(maxWidth: .infinity)
				.background(Color.white)
				.cornerRadius(8)
				.foregroundColor(.black)
				.padding(.horizontal, 32)
			}
			.padding(.bottom, 16)

			Button(action: {}) {
				HStack {
					Image(systemName: "applelogo")
						.font(.system(size: 20))
					Text("Continue with Apple")
						.fontWeight(.medium)
				}
				.padding()
				.frame(maxWidth: .infinity)
				.background(Color.white)
				.cornerRadius(8)
				.foregroundColor(.black)
				.padding(.horizontal, 32)
			}

			Spacer()
		}
		.background(Color(red: 0.69, green: 0.75, blue: 1.0))
		.ignoresSafeArea()
	}
}

#Preview {
	LaunchView()
}

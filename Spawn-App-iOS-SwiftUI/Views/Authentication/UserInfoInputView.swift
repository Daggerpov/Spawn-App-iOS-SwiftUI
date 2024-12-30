//
//  UserInfoInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct UserInfoInputView: View {
	var body: some View {
		VStack(spacing: 16) {
			Spacer()

			Text("Setup your profile?")
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.white)

			ZStack {
				Circle()
					.fill(.white)
					.frame(width: 100, height: 100)

				Circle()
					.fill(.black)
					.frame(width: 24, height: 24)
					.overlay(
						Image(systemName: "plus")
							.foregroundColor(.white)
							.font(.system(size: 12, weight: .bold))
					)
					.offset(x: 35, y: 35)
			}

			VStack(spacing: 16) {
				InputFieldView(label: "Name", placeholderText: "")
				InputFieldView(label: "Username", placeholderText: "")
			}
			.padding(.horizontal, 32)

			Spacer()

			Button(action: {}) {
				Text("Skip for now >")
					.font(.system(size: 16, weight: .semibold))
					.foregroundColor(.white)
			}
			.padding(.bottom, 32)
		}
		.background(Color(hex: "#8693FF"))
		.ignoresSafeArea()
	}
}

struct InputFieldView: View {
	var label: String
	var placeholderText: String

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(label)
				.font(.system(size: 14))
				.foregroundColor(.white)

			TextField("", text: .constant(placeholderText))
				.padding()
				.background(Color.white)
				.cornerRadius(8)
		}
	}
}

#Preview {
	UserInfoInputView()
}

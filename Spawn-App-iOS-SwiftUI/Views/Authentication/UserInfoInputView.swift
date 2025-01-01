//
//  UserInfoInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct UserInfoInputView: View {
	@State private var name: String = ""
	@State private var username: String = ""

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				Spacer()

				Text("Help your friends recognize you")
					.font(.system(size: 30, weight: .semibold))
					.foregroundColor(.white)
					.multilineTextAlignment(.center)

				Spacer()

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

				Spacer()

				VStack(spacing: 16) {
					InputFieldView(label: "Name", text: Binding(get: { name }, set: { name = $0}))
					InputFieldView(label: "Username", text: Binding(get: { username }, set: { username = $0}))
				}
				.padding(.horizontal, 32)

				HStack {
					Spacer()
					NavigationLink(destination: {
						FeedView()
							.navigationBarTitle("")
							.navigationBarHidden(true)
					}) {
						Text("Enter Spawn >")
							.font(.system(size: 20, weight: .semibold))
							.foregroundColor(.white)
					}
				}
				.padding(.horizontal, 32)
				Spacer()
				Spacer()
				Spacer()
				Spacer()
			}
			.padding()
			.background(Color(hex: "#8693FF"))
			.ignoresSafeArea()
		}
	}
}

struct InputFieldView: View {
	var label: String

	@Binding var text: String

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(label)
				.font(.system(size: 18))
				.foregroundColor(.white)

			TextField("", text: $text)
				.padding()
				.background(Color.white)
				.cornerRadius(universalRectangleCornerRadius)
		}
	}
}

#Preview {
	UserInfoInputView()
}

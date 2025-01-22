//
//  CreatingTagRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-22.
//

import SwiftUI

struct CreatingTagRowView: View {
	@EnvironmentObject var viewModel: TagsViewModel

	@State private var isExpanded: Bool = false

	// Friend Tag Creation Properties:
	@State private var displayName: String = ""
	@State private var colorHexCode: String = ""

	var body: some View {
		VStack{
			HStack {
				Group{
					if isExpanded {
						TextField("", text: $displayName)
							.underline()
						Button(action: {
							// TODO: fill in action to rename title later
						}) {
							Image(systemName: "done")
						}
					} else {
						Text(displayName)
					}
				}
				.foregroundColor(.white)
				.font(.title)
				.fontWeight(.semibold)

				Spacer()
				HStack(spacing: -10) {
					ForEach(0..<2) { _ in
						Circle()
							.frame(width: 30, height: 30)
							.foregroundColor(.gray.opacity(0.2))
					}
					Button(action: {
						withAnimation {
							isExpanded.toggle() // Toggle expanded state

						}
					}) {
						Image(systemName: "plus.circle")
							.font(.system(size: 24))
							.foregroundColor(universalAccentColor)
					}
				}
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.fill(Color(hex: colorHexCode))
			)
			if isExpanded {
				VStack(spacing: 15) {
					HStack {
						Spacer()
					}

					ColorOptions()
				}
				.padding(.horizontal)
				.padding(.bottom)
			}
		}

	}
}

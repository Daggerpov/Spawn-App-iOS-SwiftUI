//
//  ActivityCreationCenteredTitleHeader.swift
//  Spawn-App-iOS-SwiftUI
//
//  Centered title bar with optional back control and trailing balance spacer.
//

import SwiftUI

struct ActivityCreationCenteredTitleHeader: View {
	let title: String
	let titleColor: Color
	let onBack: (() -> Void)?

	var body: some View {
		HStack {
			if let onBack = onBack {
				ActivityBackButton {
					onBack()
				}
			}

			Spacer()

			Text(title)
				.font(.onestSemiBold(size: 20))
				.foregroundColor(titleColor)

			Spacer()

			InvisibleBalanceButton()
		}
		.padding(.horizontal, screenEdgePadding())
		.padding(.vertical, 12)
	}
}

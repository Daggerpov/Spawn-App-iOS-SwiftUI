//
//  ActivityLoadingCard.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//
import SwiftUI

struct ActivityLoadingCard: View {
	let activity: CalendarActivityDTO
	let color: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			// Top Row: Title and icon
			HStack(alignment: .top) {
				VStack(alignment: .leading, spacing: 4) {
					Text(activity.title ?? "Activity")
						.font(.onestBold(size: 24))
						.foregroundColor(.white)
						.redacted(reason: .placeholder)

					Text("Loading details...")
						.font(.onestRegular(size: 14))
						.foregroundColor(.white.opacity(0.85))
				}
				Spacer()

				// Activity icon
				Text(activity.icon ?? "📅")
					.font(.system(size: 24))
			}

			// Location placeholder
			HStack {
				Text(Image(systemName: "mappin.and.ellipse"))
					.foregroundColor(.white)
					.font(.onestSemiBold(size: 12))
				Text("Loading location...")
					.foregroundColor(.white)
					.font(.onestSemiBold(size: 14))
					.redacted(reason: .placeholder)
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.background(Color.black.opacity(0.18))
			.cornerRadius(100)
		}
		.padding(14)
		.background(
			RoundedRectangle(cornerRadius: 14)
				.fill(color)
		)
		.shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
		.overlay(
			// Loading indicator
			VStack {
				HStack {
					Spacer()
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle(tint: .white))
						.scaleEffect(0.8)
				}
				Spacer()
			}
			.padding(14)
		)
	}
}

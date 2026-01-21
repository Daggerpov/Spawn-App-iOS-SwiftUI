//
//  ProfileStatsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileStatsView: View {
	var profileViewModel: ProfileViewModel

	// Adaptive color for stats that works in both light and dark mode
	private var statsColor: Color {
		Color(
			UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor(Color(hex: colorsGray300))  // Lighter gray for dark mode
				default:
					return UIColor(Color(hex: colorsGray400))  // Original gray for light mode
				}
			})
	}

	var body: some View {
		HStack(spacing: 48) {
			VStack(spacing: 4) {
				HStack {
					Image(systemName: "link")
						.font(.system(size: 16))
						.foregroundColor(statsColor)

					Text("\(profileViewModel.userStats?.peopleMet ?? 0)")
						.font(.system(size: 20, weight: .bold))
						.foregroundColor(statsColor)
				}
				Text("People\nmet")
					.font(.caption2)
					.multilineTextAlignment(.center)
					.foregroundColor(statsColor)
			}

			VStack(spacing: 4) {
				HStack {
					Image(systemName: "star.fill")
						.font(.system(size: 16))
						.foregroundColor(statsColor)

					Text("\(profileViewModel.userStats?.spawnsMade ?? 0)")
						.font(.system(size: 20, weight: .bold))
						.foregroundColor(statsColor)
				}
				Text("Spawns\nmade")
					.font(.caption2)
					.multilineTextAlignment(.center)
					.foregroundColor(statsColor)
			}

			VStack(spacing: 4) {
				HStack {
					Image(systemName: "calendar.badge.plus")
						.font(.system(size: 16))
						.foregroundColor(statsColor)

					Text("\(profileViewModel.userStats?.spawnsJoined ?? 0)")
						.font(.system(size: 20, weight: .bold))
						.foregroundColor(statsColor)
				}
				Text("Spawns\njoined")
					.font(.caption2)
					.multilineTextAlignment(.center)
					.foregroundColor(statsColor)
			}
		}
	}
}

#Preview {
	ProfileStatsView(
		profileViewModel: ProfileViewModel(userId: UUID())
	)
}

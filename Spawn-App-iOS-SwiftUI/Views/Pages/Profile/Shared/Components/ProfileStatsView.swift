//
//  ProfileStatsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileStatsView: View {
	var profileViewModel: ProfileViewModel

	var body: some View {
		HStack(spacing: 48) {
			VStack(spacing: 4) {
				HStack {
					Image(systemName: "link")
						.font(.system(size: 16))
						.foregroundColor(figmaBlack400)

					Text("\(profileViewModel.userStats?.peopleMet ?? 0)")
						.font(.system(size: 20, weight: .bold))
						.foregroundColor(figmaBlack400)
				}
				Text("People\nmet")
					.font(.caption2)
					.multilineTextAlignment(.center)
					.foregroundColor(figmaBlack400)
			}

			VStack(spacing: 4) {
				HStack {
					Image(systemName: "star.fill")
						.font(.system(size: 16))
						.foregroundColor(figmaBlack400)

					Text("\(profileViewModel.userStats?.spawnsMade ?? 0)")
						.font(.system(size: 20, weight: .bold))
						.foregroundColor(figmaBlack400)
				}
				Text("Spawns\nmade")
					.font(.caption2)
					.multilineTextAlignment(.center)
					.foregroundColor(figmaBlack400)
			}

			VStack(spacing: 4) {
				HStack {
					Image(systemName: "calendar.badge.plus")
						.font(.system(size: 16))
						.foregroundColor(figmaBlack400)

					Text("\(profileViewModel.userStats?.spawnsJoined ?? 0)")
						.font(.system(size: 20, weight: .bold))
						.foregroundColor(figmaBlack400)
				}
				Text("Spawns\njoined")
					.font(.caption2)
					.multilineTextAlignment(.center)
					.foregroundColor(figmaBlack400)
			}
		}
	}
}

#Preview {
	ProfileStatsView(
		profileViewModel: ProfileViewModel(userId: UUID())
	)
}

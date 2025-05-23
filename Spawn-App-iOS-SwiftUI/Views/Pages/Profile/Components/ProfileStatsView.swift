//
//  ProfileStatsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileStatsView: View {
    @StateObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        HStack(spacing: 35) {
            VStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text("\(profileViewModel.userStats?.peopleMet ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(universalAccentColor)

                Text("People\nmet")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text("\(profileViewModel.userStats?.spawnsMade ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(universalAccentColor)

                Text("Spawns\nmade")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 4) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text("\(profileViewModel.userStats?.spawnsJoined ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(universalAccentColor)

                Text("Spawns\njoined")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ProfileStatsView(
        profileViewModel: ProfileViewModel(userId: UUID())
    )
} 
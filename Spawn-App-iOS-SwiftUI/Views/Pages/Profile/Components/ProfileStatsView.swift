//
//  ProfileStatsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Lee on 11/09/24.
//

import SwiftUI

struct ProfileStatsView: View {
    let userStats: UserStatsDTO?
    
    var body: some View {
        HStack(spacing: 48) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 16))
                        .foregroundColor(figmaBlack400)

                    Text("\(userStats?.peopleMet ?? 0)")
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

                    Text("\(userStats?.spawnsMade ?? 0)")
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

                    Text("\(userStats?.spawnsJoined ?? 0)")
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
    ProfileStatsView(userStats: UserStatsDTO(
        peopleMet: 12,
        spawnsMade: 5,
        spawnsJoined: 3
    ))
} 

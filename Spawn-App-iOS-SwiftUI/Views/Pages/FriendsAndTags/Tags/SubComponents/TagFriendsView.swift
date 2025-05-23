//
//  TagFriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-11.
//

import SwiftUI

struct TagFriendsView: View {
    var friends: [BaseUserDTO]?
    @Binding var isExpanded: Bool
    
    // Computed properties to use throughout the view
    private var displayedFriends: [BaseUserDTO] {
        return (friends ?? []).prefix(3).map { $0 }
    }
    
    private var remainingCount: Int {
        return (friends?.count ?? 0) - displayedFriends.count
    }
    
    private var trailingPadding: CGFloat {
        return min(CGFloat(displayedFriends.count) * 15, 45) + (remainingCount > 0 ? 30 : 0)
    }

    var body: some View {
        HStack {
            ZStack {
                // Show only up to 3 friends
                ForEach(
                    Array(displayedFriends.enumerated().reversed()), id: \.element.id
                ) { index, friend in
                    if let pfpUrl = friend.profilePicture {
                        AsyncImage(url: URL(string: pfpUrl)) { image in
                            image
                                .ProfileImageModifier(imageType: .eventParticipants)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 25, height: 25)
                        }
                        .offset(x: CGFloat(index) * 15)  // Adjust overlap spacing
                    } else {
                        Circle()
                            .fill(.gray)
                            .frame(width: 25, height: 25)
                            .offset(x: CGFloat(index) * 15)  // Adjust overlap spacing
                    }
                }
                
                // Show "+X" indicator if there are more than 3 friends
                if remainingCount > 0 {
                    Text("+\(remainingCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 25, height: 25)
                        .background(Circle().fill(universalAccentColor))
                        .offset(x: 45)  // Position after the 3rd friend
                }
            }
            .padding(.trailing, trailingPadding)
            
            // Add an expand/collapse button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()  // Toggle expanded state
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.3)))
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    @Previewable @State var isExpanded = false
    TagFriendsView(friends: [BaseUserDTO.danielAgapov], isExpanded: $isExpanded).environmentObject(appCache)
} 
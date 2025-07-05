//
//  ProfileInterestsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileInterestsView: View {
    let user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var editingState: ProfileEditText
    @Binding var newInterest: String
    
    var openSocialMediaLink: (String, String) -> Void
    var removeInterest: (String) -> Void
    
    // Check if this is the current user's profile
    var isCurrentUserProfile: Bool {
        if MockAPIService.isMocking {
            return true
        }
        guard let currentUser = UserAuthViewModel.shared.spawnUser else { return false }
        return currentUser.id == user.id
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Interests content
            Group {
                if profileViewModel.isLoadingInterests {
                    interestsLoadingView
                } else {
                    interestsContentView
                }
            }
            .padding(.top, 24)  // Add padding to push content below the header

            // Position the header to be centered on the top border
            interestsSectionHeader
                .padding(.leading, 6)
        }
    }

    private var interestsSectionHeader: some View {
        HStack {
            Text("Interests + Hobbies")
				.font(.onestBold(size: 14))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(figmaBittersweetOrange)
                .cornerRadius(12)

            Spacer()

            // Social media icons
            if !profileViewModel.isLoadingSocialMedia {
                socialMediaIcons
            }
        }
        .padding(.horizontal)
    }

    private var socialMediaIcons: some View {
        HStack(spacing: 10) {
            if let whatsappLink = profileViewModel.userSocialMedia?
                .whatsappLink, !whatsappLink.isEmpty
            {
                Image("whatsapp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-8))
                    .onTapGesture {
                        openSocialMediaLink(
                            "WhatsApp",
                            whatsappLink
                        )
                    }
            }

            if let instagramLink = profileViewModel.userSocialMedia?
                .instagramLink, !instagramLink.isEmpty
            {
                Image("instagram")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(8))
                    .onTapGesture {
                        openSocialMediaLink(
                            "Instagram",
                            instagramLink
                        )
                    }
            }
        }
    }

    private var interestsLoadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    private var interestsContentView: some View {
        ZStack(alignment: .topLeading) {
            // Background for interests section
            RoundedRectangle(cornerRadius: 15)
                .stroke(figmaBittersweetOrange, lineWidth: 1)
                .background(universalBackgroundColor.opacity(0.5).cornerRadius(15))

            if profileViewModel.userInterests.isEmpty {
                emptyInterestsView
            } else {
                // Interests as chips with flexible flow layout on iOS 16+, fallback to LazyVGrid
                if #available(iOS 16.0, *) {
                    FlowLayout(alignment: .leading, spacing: 8) {
                        ForEach(profileViewModel.userInterests, id: \.self) { interest in
                            interestChip(interest: interest)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .animation(.easeInOut(duration: 0.3), value: profileViewModel.userInterests)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 70, maximum: 150), spacing: 8)
                        ],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(profileViewModel.userInterests, id: \.self) { interest in
                            interestChip(interest: interest)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .animation(.easeInOut(duration: 0.3), value: profileViewModel.userInterests)
                }
            }
        }
        .frame(minHeight: 80)
        .padding(.horizontal)
    }

    private var emptyInterestsView: some View {
        Text("No interests added yet.")
            .foregroundColor(.secondary)
            .italic()
            .padding()
            .padding(.top, 12)
    }

    private func interestChip(interest: String) -> some View {
		Group{
			if isCurrentUserProfile && editingState == .save {
				Text(interest)
					.font(.onestSemiBold(size: 12))
					.padding(.vertical, 8)
					.padding(.horizontal, 14)
					.foregroundColor(.primary)
					.lineLimit(1)
					.background(universalBackgroundColor)
					.clipShape(Capsule())
					.overlay(
						RoundedRectangle(cornerRadius: 20)
							.stroke(figmaBittersweetOrange, lineWidth: 1)
					)
					.shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
					.overlay(
						isCurrentUserProfile && editingState == .save
						? HStack {
							Spacer()
							Button(action: {
								removeInterest(interest)
							}) {
								Image(systemName: "xmark.circle.fill")
									.foregroundColor(.red)
									.font(.caption)
							}
							.offset(x: 5, y: -8)
						} : nil
					)
			} else {
				Text(interest)
					.font(.onestSemiBold(size: 12))
					.padding(.vertical, 6)
					.padding(.horizontal, 12)
					.foregroundColor(.primary)
					.lineLimit(1)
					.background(Color.gray.opacity(0.1))
					.clipShape(Capsule())
					.overlay(
						RoundedRectangle(cornerRadius: 20)
							.stroke(Color.gray.opacity(0.3), lineWidth: 1)
					)
			}
		}
    }
}

// MARK: - InterestsTagsView Component
struct InterestsTagsView: View {
    let interests: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Background container
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 1, green: 0.45, blue: 0.44), lineWidth: 0.5)
                .background(.white)
                .frame(height: 100)
                .overlay(
                    // Interests positioned manually to match Figma
                    ZStack {
                        // Row 1
                        HStack(spacing: 20) {
                            if interests.count > 0 {
                                Text(interests[0])
									.font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                            if interests.count > 1 {
                                Text(interests[1])
                                    .font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                            if interests.count > 2 {
                                Text(interests[2])
                                    .font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                        }
                        .offset(y: -25)
                        
                        // Row 2
                        HStack(spacing: 40) {
                            if interests.count > 3 {
                                Text(interests[3])
                                    .font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                            if interests.count > 4 {
                                Text(interests[4])
                                    .font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                            if interests.count > 5 {
                                Text(interests[5])
                                    .font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                        }
                        .offset(y: 0)
                        
                        // Row 3
                        HStack(spacing: 30) {
                            if interests.count > 6 {
                                Text(interests[6])
                                    .font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                            if interests.count > 7 {
                                Text(interests[7])
                                    .font(.onestSemiBold(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                        }
                        .offset(y: 25)
                    }
                )
        }
    }
}

// MARK: - ActivityCalendarGrid Component
struct ActivityCalendarGrid: View {
    var body: some View {
        VStack(spacing: 4.57) {
            // Grid rows
            ForEach(0..<5) { row in
                HStack(spacing: 4.57) {
                    ForEach(0..<7) { column in
                        ActivityCalendarCell(row: row, column: column)
                    }
                }
            }
        }
    }
}

struct ActivityCalendarCell: View {
    let row: Int
    let column: Int
    
    private var backgroundColor: Color {
        // Define specific cells that should have activity colors
        let activeCells: [(Int, Int)] = [
            (0, 5), (0, 6), // Row 0 - last two cells
            (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), // Row 1 - all cells
            (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), // Row 2 - all cells
            (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), // Row 3 - all cells
            (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), // Row 4 - all cells
        ]
        
        // Special colored cells with activities
        let specialCells: [(Int, Int, Color)] = [
            (1, 3, Color(red: 1, green: 0.57, blue: 0.57)), // Pink
            (1, 4, Color(red: 0.35, green: 0.93, blue: 0.88)), // Cyan
            (1, 6, Color(red: 1, green: 0.62, blue: 0.42)), // Orange
            (2, 1, Color(red: 0.88, green: 0.36, blue: 0.45)), // Dark pink
            (2, 4, Color(red: 0.59, green: 0.59, blue: 1)), // Blue
            (3, 0, Color(red: 0.37, green: 0.88, blue: 0.16)), // Green
            (4, 2, Color(red: 0.36, green: 0.94, blue: 0.75)), // Turquoise
            (4, 4, Color(red: 0.87, green: 0.61, blue: 1)), // Purple
            (4, 5, Color(red: 1, green: 0.87, blue: 0.36)), // Yellow
        ]
        
        // Check if this cell has a special color
        for (r, c, color) in specialCells {
            if row == r && column == c {
                return color
            }
        }
        
        // Check if this cell should be active (gray)
        for (r, c) in activeCells {
            if row == r && column == c {
                return Color(red: 0.86, green: 0.84, blue: 0.84)
            }
        }
        
        // Default empty cell
        return Color.clear
    }
    
    private var hasEmoji: Bool {
        // Define cells that should have emojis
        let emojiCells: [(Int, Int)] = [
            (1, 4), // Computer
            (1, 6), // Party
            (2, 1), // Sushi
            (2, 4), // Game controller
            (3, 0), // Running
            (4, 2), // Airplane
            (4, 4), // Car
            (4, 5), // Beach
        ]
        
        for (r, c) in emojiCells {
            if row == r && column == c {
                return true
            }
        }
        return false
    }
    
    private var emoji: String {
        switch (row, column) {
        case (1, 4): return "💻"
        case (1, 6): return "🎉"
        case (2, 1): return "🍣"
        case (2, 4): return "🎮"
        case (3, 0): return "🏃"
        case (4, 2): return "✈️"
        case (4, 4): return "🚗"
        case (4, 5): return "🏖️"
        default: return ""
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4.57)
            .fill(backgroundColor)
            .frame(width: 32, height: 32)
            .overlay(
                RoundedRectangle(cornerRadius: 4.57)
                    .stroke(backgroundColor == .clear ? Color(red: 0.86, green: 0.84, blue: 0.84) : Color.clear, lineWidth: 0.57)
            )
            .shadow(
                color: backgroundColor != .clear ? Color.black.opacity(0.1) : Color.clear,
                radius: 4.57,
                x: 0,
                y: 1.14
            )
            .overlay(
                Group {
                    if hasEmoji {
                        Text(emoji)
                            .font(.system(size: 18))
                    }
                }
            )
    }
}

#Preview {
    ProfileInterestsView(
        user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(),
        editingState: .constant(.edit),
        newInterest: .constant(""),
        openSocialMediaLink: { _, _ in },
        removeInterest: { _ in }
    )
} 

//
//  AddFriendToTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-12.
//

import SwiftUI

struct AddFriendToTagView: View {
    let user: BaseUserDTO
    @State private var selectedTagId: UUID? = nil
    @State private var showArrow: Bool = false
    @State private var arrowStart: CGPoint = .zero
    @State private var arrowEnd: CGPoint = .zero
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChooseTagPopUpViewModel
    
    init(user: BaseUserDTO) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ChooseTagPopUpViewModel(
            userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
            apiService: MockAPIService.isMocking ? MockAPIService(userId: UUID()) : APIService()
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            universalBackgroundColor.ignoresSafeArea()
            
            VStack {
                // Header with back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(universalAccentColor)
                    }
                    
                    Spacer()
                    
                    Text("Add to Tag")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                Spacer()
                
                // Tags and user display
                ZStack {
                    // Profile picture in center
                    ProfileImageView(user: user)
                        .scaleEffect(1.5)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                    
                    // Tag bubbles arranged around profile
                    ForEach(viewModel.tags) { tag in
                        let isSelected = selectedTagId == tag.id
                        let position = getTagPosition(for: tag, in: viewModel.tags)
                        
                        FriendTagBubble(tag: tag, isSelected: isSelected)
                            .position(position)
                            .onTapGesture {
                                handleTagSelection(tag, at: position)
                            }
                    }
                    
                    // Arrow from user to selected tag (conditionally visible)
                    if showArrow, let selectedId = selectedTagId {
                        ArrowShape(start: arrowStart, end: arrowEnd)
                            .stroke(
                                Color(hex: viewModel.tags.first(where: { $0.id == selectedId })?.colorHexCode ?? universalSecondaryColorHexCode),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .animation(.easeInOut(duration: 0.3), value: arrowEnd)
                    }
                }
                .frame(height: 400)
                .padding(.bottom, 40)
                
                // Instructional text
                Text("Where do you want to put \(user.name ?? user.username)?")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
                Text("Tap a tag to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                
                Spacer()
                
                // Finish button
                Button(action: {
                    if let tagId = selectedTagId {
                        addFriendToTag(tagId: tagId)
                    }
                }) {
                    Text("Finish Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTagId != nil ? universalSecondaryColor : Color.gray.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(selectedTagId == nil)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchTagsToAddToFriend(friendUserId: user.id)
            }
        }
    }
    
    private func addFriendToTag(tagId: UUID) {
        // Set the single tag
        viewModel.selectedTags = [tagId]
        
        // Add the friend to the selected tag
        Task {
            await viewModel.addTagsToFriend(friendUserId: user.id)
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func handleTagSelection(_ tag: FullFriendTagDTO, at position: CGPoint) {
        // Toggle selection
        if selectedTagId == tag.id {
            selectedTagId = nil
            showArrow = false
        } else {
            selectedTagId = tag.id
            
            // Calculate arrow positions
            let center = CGPoint(x: UIScreen.main.bounds.width / 2, y: 200)
            arrowStart = center
            arrowEnd = position
            
            // Show arrow with animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showArrow = true
            }
        }
    }
    
    private func getTagPosition(for tag: FullFriendTagDTO, in allTags: [FullFriendTagDTO]) -> CGPoint {
        guard let index = allTags.firstIndex(where: { $0.id == tag.id }) else {
            return CGPoint(x: UIScreen.main.bounds.width / 2, y: 200)
        }
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight: CGFloat = 400 // Height of the ZStack frame
        let centerX = screenWidth / 2
        let centerY: CGFloat = 200 // Midpoint of the ZStack
        
        // Calculate positions based on number of tags
        let count = allTags.count
        let radius: CGFloat = 150 // Distance from center
        
        switch count {
        case 1:
            return CGPoint(x: centerX, y: centerY - radius)
        case 2:
            let angles = [-CGFloat.pi/4, CGFloat.pi*3/4]
            let angle = angles[index]
            return CGPoint(
                x: centerX + radius * cos(angle),
                y: centerY + radius * sin(angle)
            )
        case 3:
            let angles = [-CGFloat.pi/4, CGFloat.pi/2, CGFloat.pi*5/4]
            let angle = angles[index]
            return CGPoint(
                x: centerX + radius * cos(angle),
                y: centerY + radius * sin(angle)
            )
        case 4:
            let angles = [-CGFloat.pi/4, CGFloat.pi/4, CGFloat.pi*3/4, CGFloat.pi*5/4]
            let angle = angles[index]
            return CGPoint(
                x: centerX + radius * cos(angle),
                y: centerY + radius * sin(angle)
            )
        case 5:
            let angles = [-CGFloat.pi/4, CGFloat.pi/8, CGFloat.pi/2, CGFloat.pi*7/8, CGFloat.pi*5/4]
            let angle = angles[index]
            return CGPoint(
                x: centerX + radius * cos(angle),
                y: centerY + radius * sin(angle)
            )
        default:
            // For more than 5 tags, distribute evenly in a circle
            let angle = 2 * CGFloat.pi / CGFloat(count) * CGFloat(index)
            return CGPoint(
                x: centerX + radius * cos(angle),
                y: centerY + radius * sin(angle)
            )
        }
    }
}

// Profile image view
struct ProfileImageView: View {
    let user: BaseUserDTO
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 100, height: 100)
                .blur(radius: 15)
            
            // Profile picture
            if let pfpUrl = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(pfpUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                } else {
                    AsyncImage(url: URL(string: pfpUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
            }
        }
    }
}

// Modified TagBubble specific to this view
struct FriendTagBubble: View {
    let tag: FullFriendTagDTO
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            // Profile images of people in the tag
            if let friends = tag.friends, !friends.isEmpty {
                HStack(spacing: -10) {
                    ForEach(friends.prefix(2)) { friend in
                        if let pfpUrl = friend.profilePicture {
                            AsyncImage(url: URL(string: pfpUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 25, height: 25)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 25, height: 25)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            }
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 25, height: 25)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        }
                    }
                    
                    if (friends.count > 2) {
                        Text("+\(friends.count - 2)")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 25, height: 25)
                            .background(Circle().fill(Color(hex: tag.colorHexCode)))
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    }
                }
                .offset(x: 10) // Adjust positioning to center
            }
            
            // Tag bubble
            Text(tag.displayName)
                .font(.headline)
                .foregroundColor(isSelected ? .white : Color(hex: tag.colorHexCode))
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: tag.colorHexCode) : Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                )
                .overlay(
                    Capsule()
                        .stroke(Color(hex: tag.colorHexCode), lineWidth: isSelected ? 0 : 2)
                )
            
            // Number of people
            Text("\(tag.friends?.count ?? 0) people")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
        .frame(width: 150)
        .offset(y: isSelected ? -5 : 0) // Slight lift when selected
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Arrow shape
struct ArrowShape: Shape {
    var start: CGPoint
    var end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate the direction vector
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        
        // Normalize direction vector
        let nx = dx / length
        let ny = dy / length
        
        // Calculate perpendicular vector for arrowhead
        let px = -ny
        let py = nx
        
        // Calculate arrowhead points
        let arrowLength: CGFloat = 15
        let arrowWidth: CGFloat = 8
        
        // Position the arrow slightly before the endpoint
        let adjustedEnd = CGPoint(
            x: end.x - nx * 15, // Move back along direction vector
            y: end.y - ny * 15
        )
        
        // Main line
        path.move(to: start)
        path.addLine(to: adjustedEnd)
        
        // Arrowhead
        let arrowPoint1 = CGPoint(
            x: adjustedEnd.x - arrowLength * nx + arrowWidth * px,
            y: adjustedEnd.y - arrowLength * ny + arrowWidth * py
        )
        let arrowPoint2 = CGPoint(
            x: adjustedEnd.x - arrowLength * nx - arrowWidth * px,
            y: adjustedEnd.y - arrowLength * ny - arrowWidth * py
        )
        
        path.move(to: end)
        path.addLine(to: arrowPoint1)
        path.move(to: end)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

struct AddFriendToTagView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendToTagView(user: BaseUserDTO.danielAgapov)
    }
} 

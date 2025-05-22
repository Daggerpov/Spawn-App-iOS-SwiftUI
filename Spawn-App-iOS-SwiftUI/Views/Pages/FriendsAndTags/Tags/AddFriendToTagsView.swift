//
//  AddFriendToTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-18.
//

import SwiftUI

struct AddFriendToTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AddFriendToTagsViewModel
    @State private var tagSelectionState: TagSelectionState = .selection
    
    enum TagSelectionState {
        case selection
        case confirmation
    }
    
    var friend: Nameable

    init(friend: Nameable) {
        self.friend = friend
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: AddFriendToTagsViewModel(
            userId: userId,
            apiService: MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                universalBackgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with back button
                    header
                    
                    // Main content
                    ZStack {
                        if tagSelectionState == .selection {
                            selectionView
                                .transition(.opacity)
                        } else {
                            confirmationView
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut, value: tagSelectionState)
                    
                    // Footer button
                    footerButton
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchTagsFriendNotIn(friendUserId: friend.id)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var header: some View {
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
            
            // Empty spacer for alignment
            Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    private var selectionView: some View {
        VStack(spacing: 20) {
            // Friend profile in the center
            friendProfileView
                .padding(.top, 20)
            
            if viewModel.tags.isEmpty {
                Text("Create some friend tags to add to your new friends!")
                    .foregroundColor(universalAccentColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                // Selection instructions
                Text("Where do you want to put \(FormatterService.shared.formatFirstName(user: friend))?")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                    .multilineTextAlignment(.center)
                
                Text("Tap a tag to get started")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                
                // Tag bubbles layout with dynamic positioning
                GeometryReader { geometry in
                    ZStack {
						ForEach(viewModel.tags.indices, id: \.self) { index in
							let tag = viewModel.tags[index]
                            tagBubble(for: tag)
                                .position(tagPosition(for: index, count: viewModel.tags.count, in: geometry))
                        }
                    }
                }
                .frame(height: 350)
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    private var confirmationView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Confirmation text
                Text("Adding \(FormatterService.shared.formatFirstName(user: friend)) to \(viewModel.selectedTags.count) tags")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                // Show selected tags with connecting arrows
                ZStack {
                    ForEach(viewModel.getSelectedTags().indices, id: \.self) { index in
                        tagWithConnection(for: viewModel.getSelectedTags()[index], index: index)
                    }
                    
                    // Friend profile in center
                    friendProfileView
                        .zIndex(10)
                }
                .frame(height: 400)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private var friendProfileView: some View {
        ZStack {
            // Rainbow glow behind profile (matching Figma design)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.5),
                            Color.blue.opacity(0.5),
                            Color.green.opacity(0.3),
                            Color.yellow.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 30,
                        endRadius: 70
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 10)
            
            // Profile picture
            if let profilePictureString = friend.profilePicture {
                if MockAPIService.isMocking {
                    Image(profilePictureString)
                        .ProfileImageModifier(imageType: .profilePage)
                } else {
                    AsyncImage(url: URL(string: profilePictureString)) { image in
                        image.ProfileImageModifier(imageType: .profilePage)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 80, height: 80)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .ProfileImageModifier(imageType: .profilePage)
            }
        }
        .frame(width: 100, height: 100)
    }
    
    private func tagBubble(for tag: FullFriendTagDTO) -> some View {
        let isSelected = viewModel.selectedTags.contains(tag.id)
        let rotation = Double(tag.id.hashValue % 10) * 0.5 - 2.5 // Random rotation between -2.5 and 2.5 degrees
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.toggleTagSelection(tag.id)
            }
        }) {
            HStack {
                // Tag avatar previews (showing 2 friends in the tag)
                if let friends = tag.friends, !friends.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(friends.prefix(2).indices, id: \.self) { index in
                            if let profilePicture = friends[index].profilePicture {
                                if MockAPIService.isMocking {
                                    Image(profilePicture)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                } else {
                                    AsyncImage(url: URL(string: profilePicture)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 24, height: 24)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 24, height: 24)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    }
                                }
                            }
                        }
                        
                        // Show +X if there are more than 2 friends
                        if friends.count > 2 {
                            Text("+\(friends.count - 2)")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        }
                    }
                    .padding(.trailing, 4)
                }
                
                Text(tag.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : Color(hex: tag.colorHexCode))
                
                Spacer()
                
                Text("\(tag.friends?.count ?? 0) people")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: tag.colorHexCode) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: 1,
                            dash: isSelected ? [] : [5]
                        )
                    )
                    .foregroundColor(Color(hex: tag.colorHexCode))
            )
            .frame(width: 180) // Slightly smaller to better fit the screen
            .rotationEffect(.degrees(rotation)) // Add slight rotation for a more organic look
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func tagWithConnection(for tag: FullFriendTagDTO, index: Int) -> some View {
        let count = viewModel.getSelectedTags().count
        let position = getTagPosition(index: index, count: count)
        
        return ZStack {
            // Connection arrow
            ConnectionArrow(
                start: CGPoint(x: 200, y: 200), // Center
                end: position,
                color: Color(hex: tag.colorHexCode)
            )
            
            // Tag bubble
            tagBubble(for: tag)
                .position(position)
        }
    }
    
    private func tagPosition(for index: Int, count: Int, in geometry: GeometryProxy) -> CGPoint {
        // Calculate container dimensions
        let width = geometry.size.width
        let height = geometry.size.height
        let centerX = width / 2
        let centerY = height / 2
        
        // Define tag positions based on index
        // This creates a more organized layout matching the Figma design
        let positions: [CGPoint]
        
        switch count {
        case 1:
            positions = [CGPoint(x: centerX, y: centerY + 60)]
        case 2:
            positions = [
                CGPoint(x: centerX - 80, y: centerY + 80),
                CGPoint(x: centerX + 80, y: centerY + 80)
            ]
        case 3:
            positions = [
                CGPoint(x: centerX, y: centerY - 100), // top
                CGPoint(x: centerX - 100, y: centerY + 80), // bottom left
                CGPoint(x: centerX + 100, y: centerY + 80)  // bottom right
            ]
        case 4:
            positions = [
                CGPoint(x: centerX, y: centerY - 100), // top
                CGPoint(x: centerX + 110, y: centerY), // right
                CGPoint(x: centerX, y: centerY + 100), // bottom
                CGPoint(x: centerX - 110, y: centerY)  // left
            ]
        case 5:
            positions = [
                CGPoint(x: centerX, y: centerY - 100), // top
                CGPoint(x: centerX + 100, y: centerY - 40), // top right
                CGPoint(x: centerX + 100, y: centerY + 40), // bottom right
                CGPoint(x: centerX - 100, y: centerY + 40), // bottom left
                CGPoint(x: centerX - 100, y: centerY - 40)  // top left
            ]
        default:
            // For more than 5 tags, we'll create an evenly spaced circle
            let radius: CGFloat = min(width, height) * 0.4 // Use 40% of the container size
            let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(count)
            
            return CGPoint(
                x: centerX + radius * cos(angle),
                y: centerY + radius * sin(angle)
            )
        }
        
        return index < positions.count ? positions[index] : CGPoint(x: centerX, y: centerY)
    }
    
    // Legacy function, kept for reference
    private func tagBubbleOffset(for index: Int, count: Int) -> CGSize {
        // Distribute tags in a more natural, scattered way
        let radius: CGFloat = 150
        let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(min(count, 5))
        
        // Add some randomness for a more natural look
        let jitter = CGFloat(index % 3) * 10
        
        return CGSize(
            width: radius * cos(angle) + jitter,
            height: radius * sin(angle) + jitter
        )
    }
    
    // Helper functions for tag positioning in confirmation view
    private func getTagPosition(index: Int, count: Int) -> CGPoint {
        let containerWidth: CGFloat = 400
        let containerHeight: CGFloat = 400
        let center = CGPoint(x: containerWidth / 2, y: containerHeight / 2)
        
        if count == 1 {
            // Single tag at the bottom
            return CGPoint(x: center.x, y: center.y + 130)
        } else if count == 2 {
            // Two tags, one top right, one bottom left
            let positions = [
                CGPoint(x: center.x + 120, y: center.y - 100), // Top right
                CGPoint(x: center.x - 120, y: center.y + 100)  // Bottom left
            ]
            return positions[index]
        } else {
            // Distribute tags around the center
            let radius: CGFloat = 150
            let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(count) - CGFloat.pi / 2
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }
    }
    
    private var footerButton: some View {
        Button(action: {
            if tagSelectionState == .selection {
                if !viewModel.selectedTags.isEmpty {
                    withAnimation {
                        tagSelectionState = .confirmation
                    }
                }
            } else {
                Task {
                    await viewModel.addTagsToFriend(friendUserId: friend.id)
                    dismiss()
                }
            }
        }) {
            Text(tagSelectionState == .selection ? "Finish Up" : "Confirm")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.selectedTags.isEmpty ? Color.gray : universalAccentColor)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .disabled(viewModel.selectedTags.isEmpty)
    }
}

// Custom view for connecting arrows
struct ConnectionArrow: View {
    var start: CGPoint
    var end: CGPoint
    var color: Color
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dashed line
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(
                color,
                style: StrokeStyle(lineWidth: 2, dash: [5])
            )
            
            // Arrow tip
            Path { path in
                let angle = atan2(end.y - start.y, end.x - start.x)
                let arrowLength: CGFloat = 10
                
                let arrowPoint1 = CGPoint(
                    x: end.x - arrowLength * cos(angle - .pi/6),
                    y: end.y - arrowLength * sin(angle - .pi/6)
                )
                let arrowPoint2 = CGPoint(
                    x: end.x - arrowLength * cos(angle + .pi/6),
                    y: end.y - arrowLength * sin(angle + .pi/6)
                )
                
                path.move(to: end)
                path.addLine(to: arrowPoint1)
                path.move(to: end)
                path.addLine(to: arrowPoint2)
            }
            .stroke(color, lineWidth: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
}

// Scale button style for tag bubbles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}



// Preview
struct AddFriendToTagsView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendToTagsView(friend: BaseUserDTO.danielAgapov)
    }
} 

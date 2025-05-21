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
    
    var friend: BaseUserDTO
    
    init(friend: BaseUserDTO) {
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
                    ScrollView {
                        VStack(spacing: 20) {
                            // Different view based on state
                            if tagSelectionState == .selection {
                                selectionView
                            } else {
                                confirmationView
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Footer button
                    footerButton
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchTagsToAddToFriend(friendUserId: friend.id)
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
        VStack(spacing: 30) {
            // Friend profile in the center
            friendProfileView
            
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
                
                // Tag bubbles layout
                tagBubblesLayout
            }
        }
        .padding(.vertical, 20)
    }
    
    private var confirmationView: some View {
        VStack(spacing: 30) {
            // Friend profile in the center
            friendProfileView
            
            // Confirmation text
            Text("Adding \(FormatterService.shared.formatFirstName(user: friend)) to \(viewModel.selectedTags.count) tags")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .multilineTextAlignment(.center)
            
            // Show selected tags with connecting lines
            selectedTagsWithConnections
        }
        .padding(.vertical, 20)
    }
    
    private var friendProfileView: some View {
        ZStack {
            // Colorful glow behind the profile
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            Gradient.Stop(color: Color(red: 0.56, green: 0.39, blue: 0.91).opacity(0.6), location: 0.0),
                            Gradient.Stop(color: Color(red: 0.48, green: 0.74, blue: 0.9).opacity(0.3), location: 1.0),
                            Gradient.Stop(color: Color.clear, location: 1.2),
                        ]),
                        center: .center,
                        startRadius: 40,
                        endRadius: 60
                    )
                )
                .frame(width: 90, height: 90)
                .blur(radius: 8)
            
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
    
    private var tagBubblesLayout: some View {
        let columns = viewModel.tags.count >= 5 ? 2 : 1
        
        return VStack(spacing: 20) {
            if columns == 1 {
                // Single column layout for fewer tags
                ForEach(viewModel.tags) { tag in
                    tagBubble(for: tag)
                }
            } else {
                // Two-column layout for more tags
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(viewModel.tags) { tag in
                        tagBubble(for: tag)
                    }
                }
            }
        }
    }
    
    private func tagBubble(for tag: FullFriendTagDTO) -> some View {
        Button(action: {
            viewModel.toggleTagSelection(tag.id)
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
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(tag.friends?.count ?? 0) people")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(Color(hex: tag.colorHexCode))
            )
            .overlay(
                Capsule()
                    .stroke(viewModel.selectedTags.contains(tag.id) ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var selectedTagsWithConnections: some View {
        ZStack {
            // Selected tags positioned around the user
            ForEach(viewModel.getSelectedTags().indices, id: \.self) { index in
                let tag = viewModel.getSelectedTags()[index]
                let position = getTagPosition(index: index, count: viewModel.getSelectedTags().count)
                
                // Connection line
                if tagSelectionState == .confirmation {
                    Path { path in
                        path.move(to: CGPoint(x: 150, y: 150)) // Center point
                        path.addLine(to: position)
                    }
                    .stroke(Color(hex: tag.colorHexCode), style: StrokeStyle(lineWidth: 2, dash: [5]))
                }
                
                // Tag bubble
                tagBubble(for: tag)
                    .frame(width: 200)
                    .position(position)
            }
        }
        .frame(height: 300)
    }
    
    private var footerButton: some View {
        Button(action: {
            if tagSelectionState == .selection {
                if !viewModel.selectedTags.isEmpty {
                    // Switch to confirmation state if tags are selected
                    tagSelectionState = .confirmation
                }
            } else {
                // Complete the process
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
    
    // Helper functions for tag positioning
    private func getTagPosition(index: Int, count: Int) -> CGPoint {
        let containerSize = CGSize(width: 300, height: 300)
        let radius: CGFloat = 120
        let center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
        
        switch count {
        case 1:
            return CGPoint(x: center.x, y: center.y - radius)
        case 2:
            let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(count) - CGFloat.pi / 2
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        default:
            let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(count) - CGFloat.pi / 2
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
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

// View Model
class AddFriendToTagsViewModel: ObservableObject {
    @Published var tags: [FullFriendTagDTO] = []
    @Published var selectedTags: Set<UUID> = []
    @Published var errorMessage: String = ""
    
    var userId: UUID
    var apiService: IAPIService
    
    init(userId: UUID, apiService: IAPIService) {
        self.userId = userId
        self.apiService = apiService
    }
    
    func fetchTagsToAddToFriend(friendUserId: UUID) async {
        let urlString = APIService.baseURL + "friendTags/addUserToTags/\(userId)"
        
        if let url = URL(string: urlString) {
            let parameters: [String: String] = [
                "friendUserId": friendUserId.uuidString
            ]
            
            do {
                let fetchedTags: [FullFriendTagDTO] = try await self.apiService
                    .fetchData(from: url, parameters: parameters)
                
                await MainActor.run {
                    self.tags = fetchedTags
                }
            } catch {
                await MainActor.run {
                    self.tags = []
                    self.errorMessage = "Failed to load tags. Please try again."
                }
            }
        }
    }
    
    func addTagsToFriend(friendUserId: UUID) async {
        if let url = URL(string: APIService.baseURL + "friendTags/addUserToTags") {
            do {
                _ = try await self.apiService.sendData(
                    selectedTags,
                    to: url,
                    parameters: [
                        "friendUserId": friendUserId.uuidString
                    ]
                )
            } catch {
                await MainActor.run {
                    self.errorMessage = "There was an error adding tags to your friend. Please try again."
                }
            }
        }
    }
    
    func toggleTagSelection(_ tagId: UUID) {
        if selectedTags.contains(tagId) {
            selectedTags.remove(tagId)
        } else {
            selectedTags.insert(tagId)
        }
    }
    
    func getSelectedTags() -> [FullFriendTagDTO] {
        return tags.filter { selectedTags.contains($0.id) }
    }
}

// Preview
struct AddFriendToTagsView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendToTagsView(friend: BaseUserDTO.danielAgapov)
    }
} 

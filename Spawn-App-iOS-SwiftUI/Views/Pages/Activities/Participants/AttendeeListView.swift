import SwiftUI

struct AttendeeListView: View {
    let activity: FullFeedActivityDTO
    let activityColor: Color
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack {
                // Handle bar
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 50, height: 4)
                    .padding(.top, 12)
                
                Spacer()
                
                // Main attendees card
                VStack(alignment: .leading, spacing: 0) {
                    // Header with back button and title
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(getPageTitle())
                            .font(.onestSemiBold(size: 20))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Color.clear.frame(width: 20, height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Host section
                            hostSection(creator: activity.creatorUser)
                            
                            // Participants section
                            if let participants = activity.participantUsers, !participants.isEmpty {
                                participantsSection(participants: participants)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    .frame(maxHeight: isExpanded ? .infinity : 400)
                    
                    // Bottom handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 134, height: 5)
                        .padding(.bottom, 8)
                }
                .background(activityColor.opacity(0.80))
                .cornerRadius(20)
                .padding(.horizontal, 25)
                .frame(maxHeight: isExpanded ? .infinity : 588)
                .offset(y: dragOffset.height)
                .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isExpanded)
                .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            // Determine if we should toggle the state based on drag direction and velocity
                            let dragThreshold: CGFloat = 50
                            let velocityThreshold: CGFloat = 500
                            
                            if abs(value.translation.height) > dragThreshold || abs(value.predictedEndTranslation.height) > velocityThreshold {
                                if value.translation.height < 0 {
                                    // Dragged up - expand
                                    isExpanded = true
                                } else {
                                    // Dragged down - collapse
                                    isExpanded = false
                                }
                            }
                            
                            // Reset drag offset
                            dragOffset = .zero
                        }
                )
                
                Spacer()
            }
        }
        .background(Color.clear)
        .navigationBarHidden(true)
    }
    
    // MARK: - Host Section
    
    private func hostSection(creator: BaseUserDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Host")
                .font(.onestMedium(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Host avatar
                    if let profilePictureUrl = creator.profilePicture, let url = URL(string: profilePictureUrl) {
                        CachedProfileImage(
                            userId: creator.id,
                            url: url,
                            imageType: .chatMessage
                        )
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                            .overlay(
                                					Text(String(creator.name?.prefix(1) ?? creator.username?.prefix(1) ?? "U"))
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(creator.name ?? "Unknown")
                            .font(.onestBold(size: 16))
                            .foregroundColor(.white)
                        
                        				Text("@\(creator.username ?? "username")")
                            .font(.onestBold(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Participants Section
    
    private func participantsSection(participants: [BaseUserDTO]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(getParticipantsTitle(count: participants.count))
                .font(.onestMedium(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 12) {
                ForEach(participants, id: \.id) { participant in
                    participantRow(participant: participant)
                }
            }
        }
    }
    
    private func participantRow(participant: BaseUserDTO) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Participant avatar
                if let profilePictureUrl = participant.profilePicture, let url = URL(string: profilePictureUrl) {
                    CachedProfileImage(
                        userId: participant.id,
                        url: url,
                        imageType: .chatMessage
                    )
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .overlay(
                            					Text(String(participant.name?.prefix(1) ?? participant.username?.prefix(1) ?? "U"))
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name ?? "Unknown")
                        .font(.onestBold(size: 16))
                        .foregroundColor(.white)
                    
                    				Text("@\(participant.username ?? "username")")
                        .font(.onestBold(size: 16))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func getPageTitle() -> String {
        guard let startTime = activity.startTime else {
            return "Who's going?"
        }
        
        let now = Date()
        if startTime < now {
            return "Who attended?"
        } else {
            return "Who's going?"
        }
    }
    
    private func getParticipantsTitle(count: Int) -> String {
        guard let startTime = activity.startTime else {
            return "Going (\(count))"
        }
        
        let now = Date()
        if startTime < now {
            return "Attended (\(count))"
        } else {
            return "Going (\(count))"
        }
    }
}

 
import SwiftUI

struct ActivityParticipantsView: View {
    let activity: FullFeedActivityDTO
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.white.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            ZStack {
                // Main content background
                Color(red: 0.21, green: 0.46, blue: 1).opacity(0.80)
                    .cornerRadius(20)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top handle
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 50, height: 4)
                        .padding(.top, 12)
                    
                    Spacer()
                    
                    // Header with back button and title
                    HStack(spacing: 32) {
                        Button(action: onDismiss) {
                            Text("􀆉")
                                .font(.custom("SF Pro Display", size: 20).weight(.semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Who attended?")
                            .font(.custom("Onest", size: 20).weight(.semibold))
                            .lineSpacing(24)
                            .foregroundColor(.white)
                        
                        Text("􀆉")
                            .font(.custom("SF Pro Display", size: 20).weight(.semibold))
                            .foregroundColor(.white)
                            .opacity(0)
                    }
                    .frame(width: 375)
                    .padding(.bottom, 40)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Host section
                            hostSection(creator: activity.creatorUser)
                            
                            // Participants section
                            if let participants = activity.participantUsers, !participants.isEmpty {
                                participantsSection(participants: participants)
                            }
                        }
                        .padding(.horizontal, 26)
                    }
                    
                    Spacer()
                    
                    // Bottom handle
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color(red: 0.86, green: 0.84, blue: 0.84))
                            .frame(width: 134, height: 5)
                    }
                    .padding(.horizontal, 147)
                    .padding(.vertical, 8)
                }
            }
            .frame(width: 428, height: 603)
            .offset(y: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .cornerRadius(44)
    }
    
    // MARK: - Host Section
    
    private func hostSection(creator: BaseUserDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Host")
                .font(.custom("Onest", size: 16).weight(.medium))
                .lineSpacing(19.20)
                .foregroundColor(Color.white.opacity(0.80))
            
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
                        .shadow(color: Color.black.opacity(0.25), radius: 4.02, y: 1.61)
                    } else {
                        Circle()
                            .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.25), radius: 4.02, y: 1.61)
                            .overlay(
                                Text(String(creator.name?.prefix(1) ?? creator.username?.prefix(1) ?? "U"))
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                            )
                    }
                    
                                            Text("\(creator.name ?? "Unknown")\n@\(creator.username ?? "username")")
                        .font(.custom("Onest", size: 16).weight(.bold))
                        .lineSpacing(25.60)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("􀍠")
                    .font(.custom("SF Pro Display", size: 20))
                    .foregroundColor(.white)
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .background(Color.black.opacity(0.20))
            .cornerRadius(12)
        }
        .frame(width: 375)
    }
    
    // MARK: - Participants Section
    
    private func participantsSection(participants: [BaseUserDTO]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Going (\(participants.count))")
                .font(.custom("Onest", size: 16).weight(.medium))
                .lineSpacing(19.20)
                .foregroundColor(Color.white.opacity(0.80))
            
            VStack(spacing: 12) {
                ForEach(participants, id: \.id) { participant in
                    participantRow(participant: participant)
                }
            }
        }
        .frame(width: 375)
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
                    .shadow(color: Color.black.opacity(0.25), radius: 4.06, y: 1.62)
                } else {
                    Circle()
                        .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.25), radius: 4.06, y: 1.62)
                        .overlay(
                            Text(String(participant.name?.prefix(1) ?? participant.username?.prefix(1) ?? "U"))
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        )
                }
                
                                        Text("\(participant.name ?? "Unknown")\n@\(participant.username ?? "username")")
                    .font(.custom("Onest", size: 16).weight(.bold))
                    .lineSpacing(25.60)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("􀍠")
                .font(.custom("SF Pro Display", size: 20))
                .foregroundColor(.white)
        }
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .background(Color.black.opacity(0.20))
        .cornerRadius(12)
    }
}

#Preview {
    ActivityParticipantsView(
        activity: FullFeedActivityDTO.mockDinnerActivity,
        onDismiss: {}
    )
} 
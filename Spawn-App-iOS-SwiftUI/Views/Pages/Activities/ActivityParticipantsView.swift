import SwiftUI

struct ActivityParticipantsView: View {
    let activity: FullFeedActivityDTO
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 428, height: 889)
                .background(Color(red: 1, green: 1, blue: 1).opacity(0.60))
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            ZStack {
                Group {
                    // Decorative profile pictures in background
                    Ellipse()
                        .foregroundColor(.clear)
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                        .offset(x: 34, y: -148)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.06, y: 1.62
                        )
                    
                    // Top handle
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 50, height: 4)
                        .background(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                        .cornerRadius(100)
                        .offset(x: 0, y: -280)
                    
                    // Back button
                    Text("􀆉")
                        .font(Font.custom("SF Pro Display", size: 20).weight(.semibold))
                        .foregroundColor(.white)
                        .offset(x: -178, y: -241)
                        .onTapGesture {
                            onDismiss()
                        }
                    
                    // Title
                    Text("Who's Coming?")
                        .font(Font.custom("Onest", size: 20).weight(.semibold))
                        .lineSpacing(24)
                        .foregroundColor(.white)
                        .offset(x: 0, y: -241)
                    
                    // Decorative profile pictures
                    Ellipse()
                        .foregroundColor(.clear)
                        .frame(width: 51, height: 51)
                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                        .offset(x: 1.50, y: -187.50)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.02, y: 1.61
                        )
                    
                    Ellipse()
                        .foregroundColor(.clear)
                        .frame(width: 25, height: 25)
                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                        .offset(x: -44.50, y: -163.50)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.06, y: 1.62
                        )
                    
                    Ellipse()
                        .foregroundColor(.clear)
                        .frame(width: 40, height: 40)
                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                        .offset(x: -12, y: -134)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.06, y: 1.62
                        )
                    
                    // Bottom handle
                    VStack(alignment: .leading, spacing: 10) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 134, height: 5)
                            .background(Color(red: 0.86, green: 0.84, blue: 0.84))
                            .cornerRadius(100)
                    }
                    .padding(EdgeInsets(top: 8, leading: 147, bottom: 8, trailing: 147))
                    .frame(width: 428)
                    .offset(x: 0, y: 283.50)
                    
                    // Host section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Host")
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .lineSpacing(19.20)
                            .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // Host avatar
                                if let profilePictureUrl = activity.creatorUser.profilePicture, let url = URL(string: profilePictureUrl) {
                                    CachedProfileImage(
                                        userId: activity.creatorUser.id,
                                        url: url,
                                        imageType: .chatMessage
                                    )
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.25), radius: 4.02, y: 1.61)
                                } else {
                                    Ellipse()
                                        .foregroundColor(.clear)
                                        .frame(width: 36, height: 36)
                                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                                        .shadow(
                                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.02, y: 1.61
                                        )
                                }
                                
                                Text("\(activity.creatorUser.name ?? "Haley Wong")\n@\(activity.creatorUser.username ?? "haley_wong")")
                                    .font(Font.custom("Onest", size: 16).weight(.bold))
                                    .lineSpacing(25.60)
                                    .foregroundColor(.white)
                            }
                            
                            Text("􀍠")
                                .font(Font.custom("SF Pro Display", size: 20))
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .background(Color(red: 0, green: 0, blue: 0).opacity(0.20))
                        .cornerRadius(12)
                    }
                    .frame(width: 375)
                    .offset(x: 1.50, y: -55)
                    
                    // Participants section
                    VStack(alignment: .leading, spacing: 8) {
                        let participantCount = activity.participantUsers?.count ?? 0
                        Text("Going (\(participantCount))")
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .lineSpacing(19.20)
                            .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                        
                        // Participant rows
                        if let participants = activity.participantUsers {
                            ForEach(Array(participants.prefix(3).enumerated()), id: \.offset) { index, participant in
                                HStack(spacing: 12) {
                                    HStack(spacing: 12) {
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
                                            Ellipse()
                                                .foregroundColor(.clear)
                                                .frame(width: 36, height: 36)
                                                .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                                                .shadow(
                                                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.06, y: 1.62
                                                )
                                        }
                                        
                                        Text("\(participant.name ?? "First Last")\n@\(participant.username ?? "example_user")")
                                            .font(Font.custom("Onest", size: 16).weight(.bold))
                                            .lineSpacing(25.60)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("􀍠")
                                        .font(Font.custom("SF Pro Display", size: 20))
                                        .foregroundColor(.white)
                                }
                                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .background(Color(red: 0, green: 0, blue: 0).opacity(0.20))
                                .cornerRadius(12)
                            }
                        } else {
                            // Show placeholder rows if no participants
                            ForEach(0..<3, id: \.self) { _ in
                                HStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        Ellipse()
                                            .foregroundColor(.clear)
                                            .frame(width: 36, height: 36)
                                            .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                                            .shadow(
                                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.06, y: 1.62
                                            )
                                        
                                        Text("First Last\n@example_user")
                                            .font(Font.custom("Onest", size: 16).weight(.bold))
                                            .lineSpacing(25.60)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("􀍠")
                                        .font(Font.custom("SF Pro Display", size: 20))
                                        .foregroundColor(.white)
                                }
                                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .background(Color(red: 0, green: 0, blue: 0).opacity(0.20))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .frame(width: 375)
                    .offset(x: 1.50, y: 116)
                }
            }
            .frame(width: 428, height: 588)
            .background(Color(red: 0.33, green: 0.42, blue: 0.93).opacity(0.80))
            .cornerRadius(20)
            .offset(x: 0, y: 169)
        }
        .frame(width: 428, height: 926)
        .background(.white)
        .cornerRadius(44)
    }
}

#Preview {
    ActivityParticipantsView(
        activity: FullFeedActivityDTO.mockDinnerActivity,
        onDismiss: {}
    )
} 
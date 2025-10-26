import SwiftUI

struct SharedParticipantsContent: View {
    @ObservedObject var activity: FullFeedActivityDTO
    let onUserTap: ((BaseUserDTO) -> Void)?
    
    init(activity: FullFeedActivityDTO, onUserTap: ((BaseUserDTO) -> Void)? = nil) {
        self.activity = activity
        self.onUserTap = onUserTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            hostSection
            participantsSection
        }
    }
    
    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Host")
                .font(Font.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            
            UserItemView(user: activity.creatorUser) {
                onUserTap?(activity.creatorUser)
            }
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let participantCount = activity.participantUsers?.count ?? 0
            Text("Going (\(participantCount))")
                .font(Font.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            
            if let participants = activity.participantUsers, !participants.isEmpty {
                ForEach(participants, id: \.id) { participant in
                    UserItemView(user: participant) {
                        onUserTap?(participant)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Text("No one has joined yet")
                        .font(Font.custom("Onest", size: 16).weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Invite friends to join your activity!")
                        .font(Font.custom("Onest", size: 14).weight(.medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}


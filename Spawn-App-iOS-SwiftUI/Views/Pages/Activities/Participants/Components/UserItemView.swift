import SwiftUI

struct UserItemView: View {
    let user: BaseUserDTO
    let onTap: (() -> Void)?
    
    init(user: BaseUserDTO, onTap: (() -> Void)? = nil) {
        self.user = user
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // User avatar
            if let profilePictureUrl = user.profilePicture, let url = URL(string: profilePictureUrl) {
                CachedProfileImage(
                    userId: user.id,
                    url: url,
                    imageType: .participantsDrawer
                )
            } else {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(user.name?.first ?? user.username?.first ?? "?").uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? (user.id == UserAuthViewModel.shared.spawnUser?.id ? "You" : "User"))
                    .font(Font.custom("Onest", size: 16).weight(.bold))
                    .foregroundColor(.white)
                Text("@\(user.username ?? "user")")
                    .font(Font.custom("Onest", size: 14).weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .onTapGesture {
            onTap?()
        }
        .contentShape(Rectangle())
    }
}


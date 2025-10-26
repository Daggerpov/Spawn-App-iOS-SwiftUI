import SwiftUI

/// A cached async image specifically for profile pictures with common styling
struct CachedProfileImage: View {
    let userId: UUID
    let url: URL?
    let imageType: ProfileImageType
    
    var body: some View {
        CachedAsyncImage(
            userId: userId,
            url: url,
            content: { image in
                image
                    .ProfileImageModifier(imageType: imageType)
            },
            placeholder: {
                Circle()
                    .fill(Color.gray)
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: imageSize * 0.5, height: imageSize * 0.5)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        )
    }
    
    private var imageSize: CGFloat {
        switch imageType {
        case .feedPage:
            return 55
        case .friendsListView:
            return 36
        case .activityParticipants, .chatMessage:
            return 25
        case .participantsPopup:
            return 42.33
        case .participantsDrawer:
            return 36
        case .profilePage:
            return 150
        case .feedCardParticipants:
            return 34
        }
    }
}


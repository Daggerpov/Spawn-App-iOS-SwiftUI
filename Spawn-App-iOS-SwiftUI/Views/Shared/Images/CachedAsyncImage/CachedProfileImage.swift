import SwiftUI

/// A cached async image specifically for profile pictures with common styling
struct CachedProfileImage: View {
	let userId: UUID
	let url: URL?
	let imageType: ProfileImageType

	init(userId: UUID, url: URL?, imageType: ProfileImageType) {
		self.userId = userId
		self.url = url
		self.imageType = imageType
		print("🎨 [CachedProfileImage] Init for user \(userId), imageType: \(imageType)")
		print("   URL: \(url?.absoluteString ?? "nil")")
	}

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
					.overlay(Circle().stroke(strokeColor, lineWidth: strokeLineWidth))
			}
		)
	}

	private var imageSize: CGFloat {
		switch imageType {
		case .feedPage:
			return 55
		case .friendsListView:
			return 50
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

	private var strokeColor: Color {
		switch imageType {
		case .feedPage, .profilePage:
			return universalAccentColor
		case .activityParticipants, .chatMessage:
			return .white
		case .friendsListView, .participantsPopup, .participantsDrawer, .feedCardParticipants:
			return .clear
		}
	}

	private var strokeLineWidth: CGFloat {
		switch imageType {
		case .feedPage, .profilePage:
			return 2
		case .activityParticipants, .chatMessage:
			return 1
		case .friendsListView, .participantsPopup, .participantsDrawer, .feedCardParticipants:
			return 0
		}
	}
}

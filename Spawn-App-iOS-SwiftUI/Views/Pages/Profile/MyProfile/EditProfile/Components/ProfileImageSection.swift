import SwiftUI

// MARK: - Profile Image Section
struct ProfileImageSection: View {
	@Binding var selectedImage: UIImage?
	@Binding var showImagePicker: Bool
	@Binding var isImageLoading: Bool

	var body: some View {
		HStack {
			ZStack(alignment: .bottomTrailing) {
				if isImageLoading {
					ProgressView()
						.frame(width: 110, height: 110)
				} else if let selectedImage = selectedImage {
					Image(uiImage: selectedImage)
						.resizable()
						.scaledToFill()
						.frame(width: 110, height: 110)
						.clipShape(Circle())
				} else if let profilePicture = UserAuthViewModel.shared.spawnUser?.profilePicture,
					let userId = UserAuthViewModel.shared.spawnUser?.id
				{
					CachedProfileImageFlexible(
						userId: userId,
						url: URL(string: profilePicture),
						width: 110,
						height: 110
					)
				} else {
					Image(systemName: "person.circle.fill")
						.resizable()
						.scaledToFit()
						.frame(width: 110, height: 110)
						.foregroundColor(.gray)
				}

				// Edit button
				Circle()
					.fill(profilePicPlusButtonColor)
					.frame(width: 32, height: 32)
					.overlay(
						Image(systemName: "pencil")
							.foregroundColor(.white)
							.font(.system(size: 14))
					)
					.onTapGesture {
						showImagePicker = true
					}
			}
			Spacer()
		}
		.padding(.top, 10)
		.padding(.horizontal)
	}
}

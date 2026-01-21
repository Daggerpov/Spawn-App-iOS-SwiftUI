import SwiftUI

struct PeopleRowView: View {
	let friend: MinimalFriendDTO
	let activityType: ActivityTypeDTO
	let onProfileTap: (MinimalFriendDTO) -> Void
	@State private var showingPersonOptions = false
	@Environment(\.colorScheme) private var colorScheme

	// Theme-aware colors
	private var adaptiveNameColor: Color {
		colorScheme == .dark ? Color.white : universalAccentColor
	}

	private var adaptiveMenuButtonColor: Color {
		colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : figmaBlack300
	}

	var body: some View {
		HStack(spacing: 12) {
			HStack(spacing: 12) {
				// Profile picture
				AsyncImage(url: friend.profilePicture.flatMap { URL(string: $0) }) { image in
					image
						.resizable()
						.aspectRatio(contentMode: .fill)
				} placeholder: {
					Circle()
						.fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
				}
				.frame(width: 36, height: 36)
				.clipShape(Circle())
				.shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)

				// Name and username
				VStack(alignment: .leading, spacing: 2) {
					Text(FormatterService.shared.formatName(user: friend))
						.font(.onestSemiBold(size: 14))
						.foregroundColor(adaptiveNameColor)

					Text("@\(friend.username ?? "username")")
						.font(.onestSemiBold(size: 14))
						.foregroundColor(adaptiveNameColor)
				}
			}

			Spacer()

			// Menu button
			Button(action: {
				showingPersonOptions = true
			}) {
				Image(systemName: "ellipsis")
					.font(.system(size: 18))
					.foregroundColor(adaptiveMenuButtonColor)
			}
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.clear)
		)
		.sheet(isPresented: $showingPersonOptions) {
			ActivityTypeFriendMenuView(
				friend: friend,
				activityType: activityType,
				navigateToProfile: {
					showingPersonOptions = false
					onProfileTap(friend)
				}
			)
			.presentationDetents([.height(200)])
			.presentationDragIndicator(.visible)
		}
	}
}

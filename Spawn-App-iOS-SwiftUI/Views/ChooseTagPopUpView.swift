//
//  ChoosingTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Michael Tham on 23/1/25.
//

import SwiftUI

struct ChoosingTagPopupView: View {
	@ObservedObject var viewModel: ChooseTagPopUpViewModel
	var friend: BaseUserDTO
	var userId: UUID
	var closeCallback: () -> Void

	init(
		friend: BaseUserDTO, userId: UUID,
		closeCallback: @escaping () -> Void
	) {
		self.friend = friend
		self.userId = userId
		self.closeCallback = closeCallback
		self.viewModel = ChooseTagPopUpViewModel(
			userId: userId,
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: userId) : APIService())
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			profilePictureView(for: friend)

			userInfoView(for: friend)

			VStack(alignment: .leading, spacing: 20) {
				tagListView(for: viewModel)

				//TODO: addTagButtonView
			}
			doneButton(
				for: friend, viewModel: viewModel, closeCallback: closeCallback)
		}
		.padding(20)
		.background(universalBackgroundColor)
		.cornerRadius(universalRectangleCornerRadius)
		.frame(maxWidth: UIScreen.main.bounds.width * 0.85, maxHeight: 500)
		.shadow(radius: 10)

		.scrollDisabled(true)
		.onAppear {
			Task {
				await viewModel.fetchTagsToAddToFriend(friendUserId: friend.id)
			}
		}
	}
}

private func profilePictureView(for friend: BaseUserDTO) -> some View
{
	ZStack {
		Circle()
			.fill(
				RadialGradient(
					gradient: Gradient(stops: [
						Gradient.Stop(
							color: Color(red: 0.56, green: 0.39, blue: 0.91)
								.opacity(0.6), location: 0.0),
						Gradient.Stop(
							color: Color(red: 0.48, green: 0.74, blue: 0.9)
								.opacity(0.3), location: 1.0),
						Gradient.Stop(color: Color.clear, location: 1.2),
					]),
					center: .center,
					startRadius: 40,
					endRadius: 60
				)
			)
			.frame(width: 90, height: 90)
			.blur(radius: 8)

		Image("Spawn_Glow")
			.resizable()
			.scaledToFill()
			.frame(width: 84, height: 84)
			.clipShape(Circle())

		if let profilePictureString = friend.profilePicture {
			if MockAPIService.isMocking {
				Image(profilePictureString)
					.ProfileImageModifier(imageType: .choosingFriendTags)
			} else {
				AsyncImage(url: URL(string: profilePictureString)) {
					image in
					image
						.ProfileImageModifier(
							imageType: .choosingFriendTags)
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
	.frame(maxWidth: .infinity)
}

private func userInfoView(for friend: BaseUserDTO) -> some View {
	VStack(spacing: 4) {
		HStack(spacing: 6) {
			Image(systemName: "star.fill")
				.resizable()
				.scaledToFit()
				.frame(width: 20, height: 20)
				.foregroundColor(universalAccentColor)
				.shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

			Text(friend.username)
				.font(.system(size: 20, weight: .bold))
				.foregroundColor(universalAccentColor)
		}

		let fullName = FormatterService.shared.formatName(user: friend)
		Text(fullName.isEmpty ? "Unknown" : fullName)
			.font(.system(size: 12))
			.foregroundColor(universalAccentColor)
	}
	.frame(maxWidth: .infinity)
}

//TODO: add functionality where when tag selected, tag name shifts left and checkmark appears on right
private func tagListView(for viewModel: ChooseTagPopUpViewModel) -> some View {
	ScrollView {
		VStack(spacing: 10) {
			Text(
				viewModel.tags.isEmpty
					? "Create some friend tags to add to your new friends!"
					: "Add tags to this friend:"
			)
			.foregroundColor(universalAccentColor)
			.frame(maxWidth: .infinity)
			ForEach(viewModel.tags, id: \.id) { friendTag in
				Button(action: {
					viewModel.toggleTagSelection(friendTag.id)
				}) {
					HStack {
						Text(friendTag.displayName)
							.font(.system(size: 18, weight: .bold))
							.frame(
								maxWidth: .infinity,
								alignment: viewModel.selectedTags.contains(
									friendTag.id) ? .leading : .center)

						if viewModel.selectedTags.contains(friendTag.id) {
							Image(systemName: "checkmark")
								.foregroundColor(.white)
								.padding(.trailing, 10)
						}
					}
					.padding()
					.background(Color(hex: friendTag.colorHexCode))
					.foregroundColor(.white)
					.cornerRadius(10)
				}
			}
		}
		.padding(.horizontal, 16)
	}
	.frame(height: 200)
	.scrollIndicators(.hidden)
}

private func doneButton(
	for friend: BaseUserDTO, viewModel: ChooseTagPopUpViewModel,
	closeCallback: @escaping () -> Void
) -> some View {
	Button(action: {
		Task {
			await viewModel.addTagsToFriend(friendUserId: friend.id)
			closeCallback()
		}
	}) {
		Text("Done")
			.font(.system(size: 18, weight: .bold))
			.frame(maxWidth: .infinity)
			.padding(.vertical, 12)
			.background(universalAccentColor)
			.foregroundColor(.white)
			.cornerRadius(10)
	}
	.padding(.top, 5)
}

#Preview {
	ChoosingTagPopupView(friend: .danielAgapov, userId: UUID(), closeCallback: {})
}

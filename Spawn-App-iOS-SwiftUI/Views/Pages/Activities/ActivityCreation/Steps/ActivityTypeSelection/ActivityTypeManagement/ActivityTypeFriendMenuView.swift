import SwiftUI

// MARK: - ActivityTypeFriendMenuView
struct ActivityTypeFriendMenuView: View {
	let friend: BaseUserDTO
	let activityType: ActivityTypeDTO
	let navigateToProfile: () -> Void
	@Environment(\.dismiss) private var dismiss
	@State private var isLoading: Bool = true
	@StateObject private var activityTypeViewModel = ActivityTypeViewModel(
		userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())

	private var firstName: String {
		if let name = friend.name, !name.isEmpty {
			return name.components(separatedBy: " ").first ?? friend.username ?? "User"
		}
		return friend.username ?? "User"
	}

	var body: some View {
		MenuContainer {
			if isLoading {
				loadingContent
			} else {
				MenuContent(
					friend: friend,
					activityType: activityType,
					navigateToProfile: navigateToProfile,
					removeFromType: removeFromActivityType,
					dismiss: dismiss
				)
			}
		}
		.background(universalBackgroundColor)
		.onAppear {
			// Simulate a very brief loading state to ensure smooth animation
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				isLoading = false
			}
		}
	}

	private var loadingContent: some View {
		VStack(spacing: 16) {
			ForEach(0..<3) { _ in
				HStack {
					RoundedRectangle(cornerRadius: 4)
						.fill(Color.gray.opacity(0.2))
						.frame(height: 20)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
			}

			Divider()

			Button(action: { dismiss() }) {
				Text("Cancel")
					.font(.headline)
					.foregroundColor(universalAccentColor)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 16)
			}
			.background(universalBackgroundColor)
			.cornerRadius(12)
		}
		.background(universalBackgroundColor)
		.redacted(reason: .placeholder)
		.shimmering()
	}

	private func removeFromActivityType() {
		Task {
			await activityTypeViewModel.removeFriendFromActivityType(
				activityTypeId: activityType.id,
				friendId: friend.id
			)
			dismiss()

			// Post notification to refresh the activity type management view
			NotificationCenter.default.post(name: .activityTypesChanged, object: nil)
		}
	}
}

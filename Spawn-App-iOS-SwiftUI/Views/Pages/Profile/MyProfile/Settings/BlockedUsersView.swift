import SwiftUI

struct BlockedUsersView: View {
	@State private var viewModel = BlockedUsersViewModel()
	@ObservedObject var userAuth = UserAuthViewModel.shared
	@Environment(\.presentationMode) var presentationMode
	@State private var showUnblockConfirmation = false
	@State private var userToUnblock: BlockedUserDTO?
	@State private var showNotification = false
	@State private var notificationMessage = ""

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				UnifiedBackButton {
					presentationMode.wrappedValue.dismiss()
				}

				Spacer()

				Text("Blocked Users")
					.font(.onestSemiBold(size: 20))
					.foregroundColor(universalAccentColor)

				Spacer()

				// Invisible chevron to balance the back button
				Image(systemName: "chevron.left")
					.font(.system(size: 20, weight: .semibold))
					.foregroundColor(.clear)
			}
			.padding(.horizontal, 25)
			.padding(.vertical, 12)

			// Content
			if viewModel.isLoading {
				LoadingStateView(message: "Loading blocked users...")
			} else if viewModel.blockedUsers.isEmpty {
				emptyStateView
			} else {
				blockedUsersList
			}
		}
		.background(universalBackgroundColor)
		.navigationBarHidden(true)
		.onAppear {
			loadBlockedUsers()
		}
		.alert("Unblock User", isPresented: $showUnblockConfirmation) {
			Button("Cancel", role: .cancel) {
				print("🔄 [BlockedUsersView] Alert: Cancel button tapped")
			}
			Button("Unblock", role: .destructive) {
				print("🔄 [BlockedUsersView] Alert: Unblock button tapped")
				if let user = userToUnblock {
					print("🔄 [BlockedUsersView] Alert: userToUnblock found: \(user.blockedUsername)")
					unblockUser(user)
				} else {
					print("❌ [BlockedUsersView] Alert: userToUnblock is nil!")
				}
			}
		} message: {
			if let user = userToUnblock {
				Text("Are you sure you want to unblock \(user.blockedUsername)?")
			}
		}
		.overlay(
			notificationToast,
			alignment: .top
		)
	}

	private var emptyStateView: some View {
		VStack(spacing: 20) {
			Image(systemName: "person.crop.circle.badge.xmark")
				.font(.system(size: 50))
				.foregroundColor(.gray)

			Text("No Blocked Users")
				.font(.title2)
				.fontWeight(.semibold)
				.foregroundColor(.primary)

			Text("Users you block will appear here. You can unblock them at any time.")
				.font(.body)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemBackground))
	}

	private var blockedUsersList: some View {
		ScrollView {
			LazyVStack(spacing: 12) {
				ForEach(viewModel.blockedUsers, id: \.id) { blockedUser in
					BlockedUserRow(
						blockedUser: blockedUser,
						onUnblock: {
							print("🔄 [BlockedUsersView] Unblock row button pressed for: \(blockedUser.blockedUsername)")
							userToUnblock = blockedUser
							showUnblockConfirmation = true
						}
					)
					.padding(.horizontal)
				}
			}
			.padding(.top)
		}
		.refreshable {
			await loadBlockedUsersAsync()
		}
	}

	private var notificationToast: some View {
		Group {
			if showNotification {
				HStack {
					Image(systemName: "checkmark.circle.fill")
						.foregroundColor(.green)
					Text(notificationMessage)
						.foregroundColor(.primary)
					Spacer()
				}
				.padding()
				.background(Color(.systemBackground))
				.cornerRadius(10)
				.shadow(radius: 5)
				.padding()
				.transition(.move(edge: .top))
				.task {
					try? await Task.sleep(for: .seconds(3))
					withAnimation {
						showNotification = false
					}
				}
			}
		}
	}

	private func loadBlockedUsers() {
		Task {
			await loadBlockedUsersAsync()
		}
	}

	private func loadBlockedUsersAsync() async {
		guard let currentUserId = userAuth.spawnUser?.id else { return }
		await viewModel.loadBlockedUsers(for: currentUserId)
	}

	private func unblockUser(_ blockedUser: BlockedUserDTO) {
		guard let currentUserId = userAuth.spawnUser?.id else {
			print("❌ [BlockedUsersView] Cannot unblock: currentUserId is nil")
			notificationMessage = "Unable to unblock user. Please try logging in again."
			withAnimation {
				showNotification = true
			}
			return
		}

		print(
			"🔄 [BlockedUsersView] Attempting to unblock user: \(blockedUser.blockedUsername) (id: \(blockedUser.blockedId))"
		)

		Task {
			await viewModel.unblockUser(
				blockerId: currentUserId,
				blockedId: blockedUser.blockedId
			)

			// Check if there was an error
			if let errorMessage = viewModel.errorMessage {
				print("❌ [BlockedUsersView] Unblock failed: \(errorMessage)")
				await MainActor.run {
					notificationMessage = "Failed to unblock user: \(errorMessage)"
					withAnimation {
						showNotification = true
					}
				}
			} else {
				print("✅ [BlockedUsersView] Successfully unblocked user: \(blockedUser.blockedUsername)")
				await MainActor.run {
					notificationMessage = "\(blockedUser.blockedUsername) has been unblocked"
					withAnimation {
						showNotification = true
					}
				}
			}
		}
	}
}

struct BlockedUserRow: View {
	let blockedUser: BlockedUserDTO
	let onUnblock: () -> Void

	var body: some View {
		HStack {
			// User Avatar
			AsyncImage(url: URL(string: blockedUser.blockedProfilePicture ?? "")) { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fill)
			} placeholder: {
				Circle()
					.fill(Color.gray.opacity(0.3))
					.overlay(
						Text(String(blockedUser.blockedName.prefix(1).uppercased()))
							.font(.title2)
							.fontWeight(.semibold)
							.foregroundColor(.gray)
					)
			}
			.frame(width: 50, height: 50)
			.clipShape(Circle())

			VStack(alignment: .leading, spacing: 4) {
				Text(blockedUser.blockedName)
					.font(.headline)
					.foregroundColor(.primary)

				Text("@\(blockedUser.blockedUsername)")
					.font(.caption)
					.foregroundColor(.secondary)

				if !blockedUser.reason.isEmpty {
					Text("Reason: \(blockedUser.reason)")
						.font(.caption)
						.foregroundColor(.secondary)
						.lineLimit(2)
				}
			}

			Spacer()

			Button("Unblock") {
				onUnblock()
			}
			.foregroundColor(.blue)
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.background(Color.blue.opacity(0.1))
			.cornerRadius(8)
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
	}
}

#Preview {
	BlockedUsersView()
}

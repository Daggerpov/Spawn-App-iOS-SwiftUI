import SwiftUI

struct AddToActivityTypeView: View {
	let user: Nameable
	@Environment(\.presentationMode) var presentationMode
	@State private var selectedActivityTypes: Set<UUID> = []
	@StateObject private var viewModel = AddToActivityTypeViewModel()

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				// Background
				universalBackgroundColor
					.ignoresSafeArea()

				VStack(spacing: 0) {
					// Custom header
					HStack {
						Button(action: {
							presentationMode.wrappedValue.dismiss()
						}) {
							Image(systemName: "chevron.left")
								.font(.system(size: 18, weight: .medium))
								.foregroundColor(universalAccentColor)
						}

						Spacer()

						Text("Add to Activity Type")
							.font(.onestMedium(size: 20))
							.foregroundColor(universalAccentColor)

						Spacer()

						Image(systemName: "chevron.left")
							.font(.system(size: 18, weight: .medium))
							.foregroundColor(.clear)
					}
					.padding(.horizontal, 24)
					.padding(.top, 8)
					.padding(.bottom, 8)

					// Main content
					ScrollView {
						VStack(spacing: 24) {
							profileSection

							if viewModel.isLoading {
								ProgressView("Loading activity types...")
									.font(.onestRegular(size: 16))
									.foregroundColor(universalAccentColor)
									.padding()
							} else {
								activityTypeGrid
							}

							if let errorMessage = viewModel.errorMessage {
								Text(errorMessage)
									.font(.onestRegular(size: 14))
									.foregroundColor(.red)
									.multilineTextAlignment(.center)
									.padding(.horizontal)
							}

							Spacer(minLength: 100)
						}
						.padding(.horizontal, 16)
						.padding(.top, 20)
					}

					// Save button at bottom
					saveButton
						.padding(.horizontal, 16)
						.padding(.bottom, 100)
				}
			}
		}
		.navigationBarHidden(true)
		.task {
			await viewModel.loadActivityTypes()
		}
	}

	private var profileSection: some View {
		VStack(spacing: 16) {
			// Profile picture with glow effect
			ZStack {
				// Glow effect circles
				Group {
					Circle()
						.fill(Color.yellow.opacity(0.4))
						.frame(width: 60, height: 60)
						.blur(radius: 18)
						.offset(x: 8, y: -18)

					Circle()
						.fill(Color.pink.opacity(0.4))
						.frame(width: 60, height: 60)
						.blur(radius: 18)
						.offset(x: -9, y: 0)

					Circle()
						.fill(Color.blue.opacity(0.4))
						.frame(width: 60, height: 60)
						.blur(radius: 18)
						.offset(x: 8, y: 0)

					Circle()
						.fill(Color.green.opacity(0.4))
						.frame(width: 60, height: 60)
						.blur(radius: 18)
						.offset(x: -9, y: -18)
				}

				// Profile picture
				if let profilePicture = user.profilePicture {
					AsyncImage(url: URL(string: profilePicture)) { image in
						image
							.resizable()
							.scaledToFill()
							.frame(width: 67, height: 67)
							.clipShape(Circle())
					} placeholder: {
						Circle()
							.fill(Color.gray.opacity(0.3))
							.frame(width: 67, height: 67)
							.overlay(
								Image(systemName: "person.fill")
									.font(.system(size: 30))
									.foregroundColor(.gray)
							)
					}
				} else {
					Circle()
						.fill(Color.gray.opacity(0.3))
						.frame(width: 67, height: 67)
						.overlay(
							Image(systemName: "person.fill")
								.font(.system(size: 30))
								.foregroundColor(.gray)
						)
				}
			}

			// User info text
			VStack(spacing: 2) {
				Text(
					"Adding \(FormatterService.shared.formatName(user: user)) to \(selectedActivityTypes.count) activity types"
				)
				.font(.onestSemiBold(size: 16))
				.foregroundColor(universalAccentColor)

				Text(selectedActivityTypesText)
					.font(.onestRegular(size: 12))
					.foregroundColor(figmaBlack400)
			}
		}
	}

	private var selectedActivityTypesText: String {
		let selectedTypes = viewModel.activityTypes.filter { selectedActivityTypes.contains($0.id) }
		if selectedTypes.isEmpty {
			return "No activity types selected"
		}
		return selectedTypes.map { $0.title }.joined(separator: " & ")
	}

	private var activityTypeGrid: some View {
		LazyVGrid(
			columns: [
				GridItem(.fixed(116), spacing: 8),
				GridItem(.fixed(116), spacing: 8),
				GridItem(.fixed(116), spacing: 8),
			],
			spacing: 10
		) {
			ForEach(viewModel.activityTypes, id: \.id) { activityType in
				ActivityTypeCard(
					activityTypeDTO: activityType,
					isSelected: selectedActivityTypes.contains(activityType.id),
					onTap: {
						toggleSelection(for: activityType)
					}
				)
			}
		}
	}

	private var saveButton: some View {
		Button(action: {
			// Handle save action
			Task {
				await saveSelectedActivityTypes()
			}
		}) {
			Text(viewModel.isLoading ? "Saving..." : "Save")
				.font(.onestBold(size: 16))
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.frame(height: 56)
				.background(universalSecondaryColor)
				.cornerRadius(16)
		}
		.disabled(selectedActivityTypes.isEmpty || viewModel.isLoading)
		.opacity(selectedActivityTypes.isEmpty || viewModel.isLoading ? 0.6 : 1.0)
	}

	private func toggleSelection(for activityType: ActivityTypeDTO) {
		if selectedActivityTypes.contains(activityType.id) {
			selectedActivityTypes.remove(activityType.id)
		} else {
			selectedActivityTypes.insert(activityType.id)
		}
	}

	private func saveSelectedActivityTypes() async {
		let success = await viewModel.addUserToActivityTypes(user, selectedActivityTypeIds: selectedActivityTypes)

		await MainActor.run {
			if success {
				presentationMode.wrappedValue.dismiss()
			}
			// If not successful, the error message will be shown in the UI
			// The viewModel.errorMessage will be displayed to the user
		}
	}
}

// ViewModel for managing activity types
@MainActor
final class AddToActivityTypeViewModel: ObservableObject {
	@Published var activityTypes: [ActivityTypeDTO] = []
	@Published var isLoading = false
	@Published var errorMessage: String?

	private let dataService: DataService
	private let userId: UUID

	init(userId: UUID? = nil, dataService: DataService? = nil) {
		self.userId = userId ?? UserAuthViewModel.shared.spawnUser?.id ?? UUID()
		self.dataService = dataService ?? DataService.shared
	}

	func loadActivityTypes() async {
		isLoading = true
		errorMessage = nil

		// Use DataService to fetch activity types
		let result: DataResult<[ActivityTypeDTO]> = await dataService.read(
			.activityTypes(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let fetchedTypes, _):
			self.activityTypes = fetchedTypes
			self.isLoading = false

		case .failure(let error):
			self.errorMessage = "Failed to load activity types: \(ErrorFormattingService.shared.formatError(error))"
			self.isLoading = false
		}
	}

	func addUserToActivityTypes(_ userToAdd: Nameable, selectedActivityTypeIds: Set<UUID>) async -> Bool {
		isLoading = true
		errorMessage = nil

		defer {
			isLoading = false
		}

		// Create updated activity types with the user added
		var updatedTypes: [ActivityTypeDTO] = []

		for activityType in activityTypes {
			if selectedActivityTypeIds.contains(activityType.id) {
				// Convert Nameable to MinimalFriendDTO
				let minimalFriend: MinimalFriendDTO
				if let existingMinimal = userToAdd as? MinimalFriendDTO {
					minimalFriend = existingMinimal
				} else if let baseUser = userToAdd as? BaseUserDTO {
					minimalFriend = MinimalFriendDTO.from(baseUser)
				} else {
					// Create a MinimalFriendDTO from the Nameable properties
					minimalFriend = MinimalFriendDTO(
						id: userToAdd.id,
						username: userToAdd.username,
						name: userToAdd.name,
						profilePicture: userToAdd.profilePicture
					)
				}

				// Add user to associated friends if not already present
				if !activityType.associatedFriends.contains(where: { $0.id == minimalFriend.id }) {
					let updatedActivityType = ActivityTypeDTO(
						id: activityType.id,
						title: activityType.title,
						icon: activityType.icon,
						associatedFriends: activityType.associatedFriends + [minimalFriend],
						orderNum: activityType.orderNum,
						isPinned: activityType.isPinned
					)
					updatedTypes.append(updatedActivityType)
				}
			}
		}

		if !updatedTypes.isEmpty {
			let batchUpdateDTO = BatchActivityTypeUpdateDTO(
				updatedActivityTypes: updatedTypes,
				deletedActivityTypeIds: []
			)

			// Use DataService with WriteOperationType
			let operationType = WriteOperationType.batchUpdateActivityTypes(userId: userId, update: batchUpdateDTO)
			let result: DataResult<[ActivityTypeDTO]> = await dataService.write(operationType, body: batchUpdateDTO)

			switch result {
			case .success(let updatedActivityTypesReturned, _):
				self.activityTypes = updatedActivityTypesReturned
				return true

			case .failure(let error):
				self.errorMessage = "Failed to save activity types: \(ErrorFormattingService.shared.formatError(error))"
				return false
			}
		}

		return true
	}
}

#Preview {
	AddToActivityTypeView(user: BaseUserDTO.danielAgapov)
}

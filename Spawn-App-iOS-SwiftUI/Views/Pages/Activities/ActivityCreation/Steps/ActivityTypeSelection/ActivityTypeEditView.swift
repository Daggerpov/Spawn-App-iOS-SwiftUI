import SwiftUI

struct ActivityTypeEditView: View {
	let activityTypeDTO: ActivityTypeDTO
	let onBack: (() -> Void)?
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme

	@State private var editedTitle: String = ""
	@State private var editedIcon: String = ""
	@State private var hasChanges: Bool = false
	@State private var friendSelectionActivityType: ActivityTypeDTO?
	@State private var showEmojiPicker: Bool = false
	@State private var showErrorAlert: Bool = false
	@FocusState private var isTitleFieldFocused: Bool

	@State private var viewModel: ActivityTypeViewModel

	// Track if this is a new activity type (no associated friends yet)
	private var isNewActivityType: Bool {
		activityTypeDTO.associatedFriends.isEmpty && activityTypeDTO.title.isEmpty
	}

	init(activityTypeDTO: ActivityTypeDTO, onBack: (() -> Void)? = nil) {
		self.activityTypeDTO = activityTypeDTO
		self.onBack = onBack

		// Initialize the view model with userId
		let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
		self._viewModel = State(wrappedValue: ActivityTypeViewModel(userId: userId))
	}

	var body: some View {
		VStack(spacing: 0) {
			headerView
			mainContentView
		}
		.navigationBarHidden(true)
		.ignoresSafeArea(.keyboard, edges: .bottom)  // Prevent keyboard from pushing header up
		.sheet(isPresented: $showEmojiPicker) {
			ElegantEmojiPickerView(selectedEmoji: $editedIcon, isPresented: $showEmojiPicker)
		}
		.onAppear {
			setupInitialState()
		}
		.task {
			// Auto-focus the title field when the view appears
			try? await Task.sleep(for: .seconds(0.1))
			isTitleFieldFocused = true
		}
		.onChange(of: editedTitle) { _, _ in
			updateHasChanges()
		}
		.onChange(of: editedIcon) { _, _ in
			updateHasChanges()
		}
		.navigationDestination(item: $friendSelectionActivityType) { activityType in
			ActivityTypeFriendSelectionView(
				activityTypeDTO: activityType,
				onComplete: handleFriendSelectionComplete
			)
			.environmentObject(AppCache.shared)
		}
		.alert("Error", isPresented: $showErrorAlert) {
			Button("OK") {
				viewModel.clearError()
			}
		} message: {
			if let errorMessage = viewModel.errorMessage {
				Text(errorMessage)
			}
		}
		.onChange(of: viewModel.errorMessage) { _, newValue in
			showErrorAlert = newValue != nil
		}
		.overlay(loadingOverlay)
	}

	// MARK: - View Components

	private var headerView: some View {
		HStack {
			UnifiedBackButton {
				dismiss()
			}

			Spacer()

			Text("New Activity Type")
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
	}

	private var mainContentView: some View {
		ZStack {
			// Background - adaptive to light/dark mode
			universalBackgroundColor
				.ignoresSafeArea()

			VStack(spacing: 0) {
				circularContentView
				actionButtonsView
				Spacer()
			}
		}
	}

	private var circularContentView: some View {
		VStack(spacing: 30) {
			iconPickerView
			titleTextField
		}
		.padding(40)
		.frame(width: 290, height: 290)
		.background(
			colorScheme == .dark ? Color(red: 0.24, green: 0.23, blue: 0.23) : Color(red: 0.95, green: 0.93, blue: 0.93)
		)
		.cornerRadius(30)
		.padding(.top, 40)
	}

	private var iconPickerView: some View {
		ZStack {
			// Main circular background
			Circle()
				.fill(Color(red: 0.86, green: 0.84, blue: 0.84))
				.frame(width: 128, height: 128)

			// Icon display - make it clickable
			Button(action: {
				showEmojiPicker = true
			}) {
				Text(editedIcon)
					.font(.system(size: 40))
					.id("emoji-\(editedIcon)")
			}

			// Edit button overlay - positioned at bottom right
			editButtonOverlay
		}
		.frame(width: 128, height: 128)
	}

	private var editButtonOverlay: some View {
		VStack {
			Spacer()
			HStack {
				Spacer()
				Button(action: {
					showEmojiPicker = true
				}) {
					Image(systemName: "pencil")
						.font(.system(size: 14))
						.foregroundColor(.white)
				}
				.padding(13.59)
				.frame(width: 36.25, height: 36.25)
				.background(Color(red: 0.52, green: 0.49, blue: 0.49))
				.cornerRadius(27.19)
				.offset(x: 8, y: 8)
			}
		}
		.frame(width: 128, height: 128)
	}

	private var titleTextField: some View {
		TextField("Activity name", text: $editedTitle)
			.font(.onestMedium(size: 32))
			.foregroundColor(universalAccentColor)
			.multilineTextAlignment(.center)
			.textFieldStyle(PlainTextFieldStyle())
			.frame(maxWidth: 250)
			.focused($isTitleFieldFocused)
	}

	private var actionButtonsView: some View {
		let isButtonEnabled =
			!((isNewActivityType && editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
			|| (!hasChanges && !isNewActivityType) || viewModel.isLoading)

		return VStack(spacing: 16) {
			// Save button
			Enhanced3DButton(
				title: isNewActivityType ? "Next" : "Save",
				backgroundColor: Color(red: 0.42, green: 0.51, blue: 0.98),
				foregroundColor: .white,
				isEnabled: isButtonEnabled
			) {
				// Only proceed if validation passes
				guard !(isNewActivityType && editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) else {
					return
				}

				if isNewActivityType {
					// For new activity types, navigate to friend selection
					navigateToNextStep()
				} else {
					// For existing activity types, save changes
					saveChanges()
				}
			}
			.frame(width: 290)

			// Cancel button
			Enhanced3DButton(
				title: "Cancel",
				backgroundColor: Color.clear,
				foregroundColor: Color(red: 0.15, green: 0.14, blue: 0.14),
				borderColor: Color(red: 0.15, green: 0.14, blue: 0.14),
				isEnabled: !viewModel.isLoading
			) {
				if let onBack = onBack {
					onBack()
				} else {
					dismiss()
				}
			}
			.frame(width: 290)
		}
		.padding(.top, 60)
		.padding(.bottom, 40)
	}

	/// Handles the completion of friend selection - saves the activity type and dismisses
	private func handleFriendSelectionComplete(_ finalActivityType: ActivityTypeDTO) {
		Task {
			await viewModel.createActivityType(finalActivityType)
			// Dismiss the edit view after successful creation
			await MainActor.run {
				dismiss()
			}
		}
	}

	private var loadingOverlay: some View {
		Group {
			if viewModel.isLoading {
				ZStack {
					Color.black.opacity(0.3)
						.ignoresSafeArea()

					ProgressView("Saving...")
						.padding()
						.background(
							RoundedRectangle(cornerRadius: 12)
								.fill(universalBackgroundColor)
						)
				}
			}
		}
	}

	// MARK: - Private Methods
	private func setupInitialState() {
		editedTitle = activityTypeDTO.title
		editedIcon = activityTypeDTO.icon
		hasChanges = false
	}

	private func updateHasChanges() {
		hasChanges = (editedTitle != activityTypeDTO.title) || (editedIcon != activityTypeDTO.icon)
	}

	private func navigateToNextStep() {
		guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			return
		}

		friendSelectionActivityType = createUpdatedActivityType()
	}

	private func createUpdatedActivityType() -> ActivityTypeDTO {
		return ActivityTypeDTO(
			id: activityTypeDTO.id,
			title: editedTitle,
			icon: editedIcon,
			associatedFriends: activityTypeDTO.associatedFriends,
			orderNum: activityTypeDTO.orderNum,
			isPinned: activityTypeDTO.isPinned
		)
	}

	private func saveChanges() {
		let updatedActivityType = createUpdatedActivityType()
		Task {
			await viewModel.updateActivityType(updatedActivityType)
			// Dismiss after saving
			await MainActor.run {
				dismiss()
			}
		}
	}
}

// MARK: - Preview
@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared

	NavigationView {
		ActivityTypeEditView(activityTypeDTO: ActivityTypeDTO.createNew(), onBack: nil)
			.environmentObject(appCache)
	}
}

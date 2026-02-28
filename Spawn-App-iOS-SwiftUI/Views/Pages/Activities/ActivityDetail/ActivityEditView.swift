import SwiftUI

struct ActivityEditView: View {
	var viewModel: ActivityDescriptionViewModel
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme

	@State private var editedTitle: String = ""
	@State private var editedIcon: String = ""
	@State private var originalTitle: String = ""
	@State private var originalIcon: String = ""
	@State private var showEmojiPicker: Bool = false
	@State private var hasChanges: Bool = false
	@State private var showSuccessMessage: Bool = false
	@State private var showSaveConfirmation: Bool = false
	@State private var showErrorAlert: Bool = false
	@FocusState private var isTitleFieldFocused: Bool

	private var adaptiveBackgroundColor: Color {
		colorScheme == .dark ? Color(red: 0.24, green: 0.23, blue: 0.23) : Color(red: 0.95, green: 0.93, blue: 0.93)
	}

	private var adaptiveTextColor: Color {
		colorScheme == .dark ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.11)
	}

	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				// Header with back button
				headerView

				VStack(spacing: 40) {
					Spacer()

					VStack(spacing: 30) {
						// Icon picker area
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
							}

							// Edit button overlay - positioned at bottom right
							VStack {
								Spacer()
								HStack {
									Spacer()
									Button(action: {
										showEmojiPicker = true
									}) {
										ZStack {
											Circle()
												.fill(Color(red: 0.52, green: 0.49, blue: 0.49))
												.frame(width: 36, height: 36)

											Image(systemName: "pencil")
												.font(.system(size: 14))
												.foregroundColor(.white)
										}
									}
									.offset(x: 15, y: 15)
								}
							}
						}
						.frame(width: 128, height: 128)

						// Title text field
						TextField("Activity Title", text: $editedTitle)
							.font(.onestMedium(size: 32))
							.foregroundColor(adaptiveTextColor)
							.multilineTextAlignment(.center)
							.focused($isTitleFieldFocused)
							.textFieldStyle(PlainTextFieldStyle())
							.frame(maxWidth: 250)
					}
					.padding(40)
					.frame(width: 290, height: 290)
					.background(adaptiveBackgroundColor)
					.cornerRadius(30)
					.offset(x: 0, y: -50)

					Spacer()

					// Action buttons
					VStack(spacing: 16) {
						// Save button
						Button(action: saveChanges) {
							HStack {
								if viewModel.isLoading {
									ProgressView()
										.progressViewStyle(CircularProgressViewStyle(tint: .white))
										.scaleEffect(0.8)
									Text("Saving...")
								} else if showSuccessMessage {
									Image(systemName: "checkmark")
										.foregroundColor(.white)
									Text("Saved!")
								} else {
									Text("Save")
								}
							}
							.font(.onestSemiBold(size: 20))
							.foregroundColor(.white)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 16)
							.background(
								showSuccessMessage
									? Color.green
									: (hasChanges && !viewModel.isLoading) ? figmaBlue : figmaBlue.opacity(0.5)
							)
							.cornerRadius(16)
						}
						.frame(width: 290, height: 56)
						.disabled(!hasChanges || viewModel.isLoading)

						// Cancel button
						Button(action: {
							if hasChanges {
								showSaveConfirmation = true
							} else {
								dismiss()
							}
						}) {
							Text("Cancel")
								.font(.onestSemiBold(size: 20))
								.foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
								.frame(maxWidth: .infinity)
								.padding(.vertical, 16)
								.background(Color.clear)
								.cornerRadius(16)
								.overlay(
									RoundedRectangle(cornerRadius: 16)
										.stroke(Color(red: 0.82, green: 0.80, blue: 0.80), lineWidth: 0.5)
								)
						}
						.frame(width: 290, height: 56)
						.disabled(viewModel.isLoading)

						Spacer()
							.frame(height: 50)
					}
				}
			}
			.navigationBarHidden(true)
			.background(Color.black.opacity(0.3))
			.onAppear {
				setupInitialState()
				// Auto-focus the title field when the view appears
				Task { @MainActor in
					try? await Task.sleep(for: .seconds(0.1))
					isTitleFieldFocused = true
				}
			}
			.onChange(of: editedTitle) {
				updateHasChanges()
				// Apply optimistic update immediately
				optimisticallyUpdateActivity()
			}
			.onChange(of: editedIcon) {
				updateHasChanges()
				// Apply optimistic update immediately
				optimisticallyUpdateActivity()
			}
			.sheet(isPresented: $showEmojiPicker) {
				ElegantEmojiPickerView(selectedEmoji: $editedIcon, isPresented: $showEmojiPicker)
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
			.alert("Save All Changes?", isPresented: $showSaveConfirmation) {
				Button("Don't Save", role: .destructive) {
					// Reset to original values and dismiss
					resetToOriginalValues()
					dismiss()
				}
				Button("Save All Changes") {
					// Save changes and dismiss
					saveChanges()
				}
				Button("Cancel", role: .cancel) {
					// Stay on the current screen
				}
			} message: {
				Text("You have unsaved changes.")
			}
		}
	}

	// MARK: - Header View

	private var headerView: some View {
		HStack {
			UnifiedBackButton {
				if hasChanges {
					showSaveConfirmation = true
				} else {
					dismiss()
				}
			}

			Spacer()

			Text("Edit Activity")
				.font(.onestSemiBold(size: 20))
				.foregroundColor(adaptiveTextColor)

			Spacer()

			// Invisible chevron to balance the back button
			Image(systemName: "chevron.left")
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.clear)
		}
		.padding(.horizontal, 25)
		.padding(.vertical, 12)
	}

	// MARK: - Private Methods

	private func setupInitialState() {
		editedTitle = viewModel.activity.title ?? ""
		editedIcon = viewModel.activity.icon ?? "⭐️"
		originalTitle = viewModel.activity.title ?? ""
		originalIcon = viewModel.activity.icon ?? "⭐️"
		hasChanges = false
	}

	private func updateHasChanges() {
		hasChanges = (editedTitle != originalTitle) || (editedIcon != originalIcon)
	}

	private func optimisticallyUpdateActivity() {
		// Only update if there are actually changes
		if hasChanges {
			viewModel.optimisticallyUpdateActivity(
				title: editedTitle.isEmpty ? nil : editedTitle,
				icon: editedIcon
			)
		}
	}

	private func saveChanges() {
		Task {
			await viewModel.saveActivityChanges()

			await MainActor.run {
				if viewModel.errorMessage == nil {
					// Show success message
					showSuccessMessage = true
					hasChanges = false  // Reset changes flag

					// Auto-dismiss after showing success for 1.5 seconds
					Task { @MainActor in
						try? await Task.sleep(for: .seconds(1.5))
						dismiss()
					}
				}
			}
		}
	}

	private func resetToOriginalValues() {
		// Reset the edited values back to the original values
		editedTitle = originalTitle
		editedIcon = originalIcon
		hasChanges = false

		// Reset the activity back to original values in the view model
		viewModel.optimisticallyUpdateActivity(
			title: originalTitle.isEmpty ? nil : originalTitle,
			icon: originalIcon
		)
	}

}

#Preview {
	ActivityEditView(
		viewModel: ActivityDescriptionViewModel(
			activity: FullFeedActivityDTO.mockDinnerActivity,
			users: [],
			senderUserId: UUID(),
			dataService: DataService.shared
		))
}

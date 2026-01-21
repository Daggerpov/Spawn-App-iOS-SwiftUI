//
//  FeedbackView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-02-18.
//

import PhotosUI
import SwiftUI

// MARK: - Main Feedback View
struct FeedbackView: View {
	@State private var viewModel: FeedbackViewModel
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme

	@State private var selectedType: FeedbackType = .GENERAL_FEEDBACK
	@State private var message: String = ""
	@State private var selectedItem: PhotosPickerItem?
	@State private var selectedImage: UIImage?
	@State private var isTextFieldFocused: Bool = false

	let userId: UUID?
	let email: String?

	init(userId: UUID?, email: String?, dataService: DataService = DataService.shared) {
		self.userId = userId
		self.email = email
		_viewModel = State(wrappedValue: FeedbackViewModel(dataService: dataService))
	}

	var body: some View {
		VStack(spacing: 0) {
			// Header
			headerView

			// Content
			ScrollView {
				VStack(spacing: 24) {
					// Feedback type selector
					FeedbackTypeSelector(selectedType: $selectedType)
						.padding(.top, 10)

					// Message input
					MessageInputView(message: $message, isFocused: $isTextFieldFocused)

					// Image picker
					ImagePickerView(selectedItem: $selectedItem, selectedImage: $selectedImage)
						.onChange(of: selectedItem) { _, newItem in
							loadTransferable(from: newItem)
						}

					// Submit button
					SubmitButtonView(
						viewModel: viewModel,
						message: message,
						onSubmit: {
							Task {
								await viewModel.submitFeedback(
									type: selectedType,
									message: message,
									userId: userId,
									image: selectedImage
								)
							}
						}
					)
					.padding(.vertical, 10)

					// Success/Error message
					FeedbackStatusView(
						viewModel: viewModel,
						onSuccess: { dismiss() }
					)

					Spacer(minLength: 30)
				}
				.padding(.horizontal)
				.padding(.top, 10)
				.onTapGesture {
					if isTextFieldFocused {
						isTextFieldFocused = false
					}
				}
			}
		}
		.background(universalBackgroundColor)
		.navigationBarHidden(true)
		.ignoresSafeArea(.keyboard, edges: .bottom)  // Prevent keyboard from pushing header up
	}

	private var headerView: some View {
		HStack {
			Button(action: {
				dismiss()
			}) {
				Image(systemName: "chevron.left")
					.foregroundColor(universalAccentColor)
					.font(.title3)
					.padding(.all, 8)
					.background(
						Circle()
							.fill(universalAccentColor.opacity(0.1))
							.opacity(0)
					)
			}
			.buttonStyle(PlainButtonStyle())
			.contentShape(Rectangle())

			Spacer()

			Text("Send Feedback")
				.font(.headline)
				.foregroundColor(universalAccentColor)

			Spacer()

			// Empty view for balance
			Color.clear.frame(width: 32, height: 32)
		}
		.padding(.horizontal)
		.padding(.top, 8)
		.padding(.bottom, 16)
		.background(
			Rectangle()
				.fill(universalBackgroundColor)
				.shadow(color: universalAccentColor.opacity(0.1), radius: 1, x: 0, y: 1)
		)
	}

	private func loadTransferable(from item: PhotosPickerItem?) {
		guard let item = item else { return }

		item.loadTransferable(type: Data.self) { result in
			DispatchQueue.main.async {
				switch result {
				case .success(let data):
					if let unwrappedData = data {
						if let image = UIImage(data: unwrappedData) {
							self.selectedImage = image

						}
					}
				case .failure(let error):
					print("Photo picker error: \(error)")
				}
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	FeedbackView(userId: UUID(), email: "user@example.com").environmentObject(appCache)
}

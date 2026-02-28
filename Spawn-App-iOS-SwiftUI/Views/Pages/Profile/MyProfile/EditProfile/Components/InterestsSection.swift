import SwiftUI

// MARK: - Interests Section
struct InterestsSection: View {
	var profileViewModel: ProfileViewModel
	let userId: UUID
	@Binding var newInterest: String
	let maxInterests: Int
	@FocusState private var isTextFieldFocused: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Interests + Hobbies (Max \(maxInterests))")
				.font(.subheadline)
				.foregroundColor(.gray)

			// Text field with placeholder overlay
			ZStack(alignment: .leading) {
				// Background
				RoundedRectangle(cornerRadius: universalNewRectangleCornerRadius)
					.fill(Color(hex: colorsGray200))

				// Placeholder text
				if newInterest.isEmpty {
					Text("Type and press enter to add...")
						.font(.subheadline)
						.foregroundColor(Color(hex: colorsGray500))
						.padding(.leading, 16)
				}

				// Text field
				TextField("", text: $newInterest)
					.font(.subheadline)
					.foregroundColor(Color(hex: colorsGray900))
					.padding(.horizontal, 16)
					.padding(.vertical, 14)
					.focused($isTextFieldFocused)
					.onSubmit {
						addInterest()
					}
			}

			// Existing interests as chips
			if !profileViewModel.userInterests.isEmpty {
				// Flexible layout for interests that wraps to new lines
				LazyVGrid(
					columns: [
						GridItem(.flexible()),
						GridItem(.flexible()),
						GridItem(.flexible()),
					], spacing: 8
				) {
					ForEach(Array(profileViewModel.userInterests.enumerated()), id: \.offset) { index, interest in
						InterestChipView(interest: interest) {
							removeInterest(interest)
						}
					}
				}
				.animation(.easeInOut(duration: 0.3), value: profileViewModel.userInterests)
			}
		}
		.padding(.horizontal)
	}

	private func addInterest() {
		guard !newInterest.isEmpty else { return }
		guard profileViewModel.userInterests.count < maxInterests else {
			InAppNotificationService.shared.showErrorMessage(
				"You can have a maximum of \(maxInterests) interests",
				title: "Limit Reached"
			)
			return
		}

		let interest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)

		let isDuplicate = profileViewModel.userInterests.contains {
			$0.caseInsensitiveCompare(interest) == .orderedSame
		}
		if isDuplicate {
			InAppNotificationService.shared.showErrorMessage(
				"\"\(interest)\" is already in your interests",
				title: "Duplicate Interest"
			)
		} else {
			profileViewModel.userInterests.append(interest)
		}
		newInterest = ""
		isTextFieldFocused = false
	}

	private func removeInterest(_ interest: String) {
		// Only update local state - don't call API until save
		profileViewModel.userInterests.removeAll { $0 == interest }
	}
}

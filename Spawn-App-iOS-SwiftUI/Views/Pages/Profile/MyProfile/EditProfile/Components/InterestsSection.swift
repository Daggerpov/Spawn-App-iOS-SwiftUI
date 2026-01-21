import SwiftUI

// MARK: - Interests Section
struct InterestsSection: View {
	var profileViewModel: ProfileViewModel
	let userId: UUID
	@Binding var newInterest: String
	let maxInterests: Int
	@Binding var showAlert: Bool
	@Binding var alertMessage: String
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
			alertMessage = "You can have a maximum of \(maxInterests) interests"
			showAlert = true
			return
		}

		let interest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)

		// Don't add duplicates
		if !profileViewModel.userInterests.contains(interest) {
			// Only update local state - don't call API until save
			profileViewModel.userInterests.append(interest)
			newInterest = ""
			isTextFieldFocused = false  // Dismiss keyboard
		} else {
			newInterest = ""
			isTextFieldFocused = false  // Dismiss keyboard
		}
	}

	private func removeInterest(_ interest: String) {
		// Only update local state - don't call API until save
		profileViewModel.userInterests.removeAll { $0 == interest }
	}
}

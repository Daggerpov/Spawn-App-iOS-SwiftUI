import SwiftUI

struct ActivityTypeNameEditModal: View {
	@Binding var isPresented: Bool
	@Binding var activityTypeName: String
	@Environment(\.colorScheme) private var colorScheme
	@FocusState private var isTextFieldFocused: Bool

	let onSave: (String) -> Void
	let onCancel: () -> Void

	@State private var editedName: String = ""

	private var adaptiveOverlayColor: Color {
		colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.4)
	}

	private var adaptiveModalBackground: Color {
		colorScheme == .dark ? Color(red: 0.24, green: 0.23, blue: 0.23) : Color(red: 0.95, green: 0.93, blue: 0.93)
	}

	private var adaptiveTextColor: Color {
		colorScheme == .dark ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.11)
	}

	private var adaptiveIconBackground: Color {
		colorScheme == .dark ? Color(red: 0.40, green: 0.37, blue: 0.37) : Color(red: 0.86, green: 0.84, blue: 0.84)
	}

	var body: some View {
		ZStack {
			// Semi-transparent background overlay
			adaptiveOverlayColor
				.ignoresSafeArea()
				.onTapGesture {
					dismissModal()
				}

			// Modal content
			VStack(spacing: 30) {
				// Icon section
				VStack(spacing: 10) {
					ZStack {
						Circle()
							.fill(adaptiveIconBackground)
							.frame(width: 80, height: 80)

						ZStack {
							Circle()
								.fill(Color(red: 0.52, green: 0.49, blue: 0.49))
								.frame(width: 36, height: 36)

							Text("􀈊")
								.font(.system(size: 20, weight: .medium))
								.foregroundColor(.white)
						}
						.offset(x: 22, y: 22)
					}
					.frame(width: 128, height: 128)
					.background(adaptiveIconBackground)
					.clipShape(Circle())
				}

				// Text field
				TextField("Activity Type Name", text: $editedName)
					.font(.onestMedium(size: 32))
					.foregroundColor(adaptiveTextColor)
					.multilineTextAlignment(.center)
					.focused($isTextFieldFocused)
					.onSubmit {
						saveChanges()
					}
			}
			.padding(40)
			.frame(width: 290, height: 290)
			.background(adaptiveModalBackground)
			.cornerRadius(30)
			.shadow(radius: 20)

			// Action buttons
			VStack(spacing: 16) {
				Spacer()

				// Save button
				Button(action: saveChanges) {
					Text("Save")
						.font(.onestSemiBold(size: 20))
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(figmaBlue)
						.cornerRadius(universalRectangleCornerRadius)
				}
				.frame(width: 290)

				// Cancel button
				Button(action: dismissModal) {
					Text("Cancel")
						.font(.onestSemiBold(size: 20))
						.foregroundColor(adaptiveTextColor)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(Color.clear)
						.overlay(
							RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
								.stroke(adaptiveTextColor, lineWidth: 1)
						)
				}
				.frame(width: 290)

				Spacer()
					.frame(height: 50)
			}
		}
		.animation(.easeInOut(duration: 0.3), value: isPresented)
		.onAppear {
			editedName = activityTypeName
		}
		.task {
			// Focus the text field when modal appears
			try? await Task.sleep(for: .seconds(0.1))
			isTextFieldFocused = true
		}
	}

	private func saveChanges() {
		let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
		if !trimmedName.isEmpty {
			onSave(trimmedName)
		}
		dismissModal()
	}

	private func dismissModal() {
		isTextFieldFocused = false
		onCancel()
		withAnimation(.easeInOut(duration: 0.3)) {
			isPresented = false
		}
	}
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
	ZStack {
		Color.gray.opacity(0.3)
			.ignoresSafeArea()

		ActivityTypeNameEditModal(
			isPresented: .constant(true),
			activityTypeName: .constant("Study"),
			onSave: { name in
				print("Saving: \(name)")
			},
			onCancel: {
				print("Cancelled")
			}
		)
	}
}

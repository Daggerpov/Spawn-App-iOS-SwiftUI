import SwiftUI

struct ActivityTypeOptionsPopup: View {
	@Binding var isPresented: Bool
	let onManagePeople: () -> Void
	let onDeleteActivityType: () -> Void
	@State private var showDeleteConfirmation = false

	var body: some View {
		ZStack {
			// Semi-transparent background overlay - matching Figma exactly
			Rectangle()
				.foregroundColor(.clear)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.background(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.60))
				.ignoresSafeArea()
				.onTapGesture {
					withAnimation(.easeInOut(duration: 0.3)) {
						isPresented = false
					}
				}

			// Popup content positioned at bottom
			VStack {
				Spacer()

				VStack(alignment: .leading, spacing: 16) {
					// Main options group
					VStack(alignment: .leading, spacing: 0) {
						// Manage People option
						Button(action: {
							onManagePeople()
							withAnimation(.easeInOut(duration: 0.3)) {
								isPresented = false
							}
						}) {
							HStack(spacing: 10) {
								Text("Manage People")
									.font(Font.custom("Onest", size: 20).weight(.medium))
									.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
							}
							.padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
							.frame(height: 63)
							.frame(maxWidth: .infinity, alignment: .center)
							.background(Color(red: 0.95, green: 0.93, blue: 0.93))
							.overlay(
								Rectangle()
									.inset(by: 0.50)
									.stroke(Color(red: 0.52, green: 0.49, blue: 0.49), lineWidth: 0.50)
							)
							.shadow(
								color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
							)
						}
						.buttonStyle(PlainButtonStyle())

						// Delete Activity Type option
						Button(action: {
							showDeleteConfirmation = true
						}) {
							HStack(spacing: 10) {
								Image(systemName: "trash")
									.font(.system(size: 20, weight: .medium))
									.foregroundColor(.red)
								Text("Delete Activity Type")
									.font(Font.custom("Onest", size: 20).weight(.medium))
									.foregroundColor(.red)
							}
							.padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
							.frame(height: 63)
							.frame(maxWidth: .infinity, alignment: .center)
							.background(Color(red: 0.95, green: 0.93, blue: 0.93))
							.shadow(
								color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
							)
						}
						.buttonStyle(PlainButtonStyle())
					}
					.cornerRadius(16)

					// Cancel button
					Button(action: {
						withAnimation(.easeInOut(duration: 0.3)) {
							isPresented = false
						}
					}) {
						HStack(spacing: 10) {
							Image(systemName: "xmark")
								.font(.system(size: 20, weight: .medium))
								.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
							Text("Cancel")
								.font(Font.custom("Onest", size: 20).weight(.medium))
								.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
						}
						.padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
						.frame(height: 63)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(Color(red: 0.95, green: 0.93, blue: 0.93))
						.cornerRadius(16)
						.shadow(
							color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
						)
					}
					.buttonStyle(PlainButtonStyle())
				}
				.frame(width: 380)
				.padding(.horizontal, 24)
				.padding(.bottom, 40)
			}
		}
		.alert("Delete Activity Type", isPresented: $showDeleteConfirmation) {
			Button("Cancel", role: .cancel) {}
			Button("Delete", role: .destructive) {
				onDeleteActivityType()
				withAnimation(.easeInOut(duration: 0.3)) {
					isPresented = false
				}
			}
		} message: {
			Text("Are you sure you want to delete this activity type? This action cannot be undone.")
		}
	}
}

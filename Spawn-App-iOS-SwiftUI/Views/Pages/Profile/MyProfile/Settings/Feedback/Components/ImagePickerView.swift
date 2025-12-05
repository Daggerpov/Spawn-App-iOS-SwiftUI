import PhotosUI
import SwiftUI

// MARK: - Image Picker Component
struct ImagePickerView: View {
	@Binding var selectedItem: PhotosPickerItem?
	@Binding var selectedImage: UIImage?
	@Environment(\.colorScheme) private var colorScheme

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Attach Image (Optional)")
				.font(.headline)
				.foregroundColor(universalAccentColor)

			Spacer()

			HStack {
				Spacer()

				if let selectedImage = selectedImage {
					ZStack(alignment: .topTrailing) {
						Image(uiImage: selectedImage)
							.resizable()
							.scaledToFit()
							.frame(maxHeight: 150)
							.cornerRadius(8)

						Button(action: {
							self.selectedImage = nil
							self.selectedItem = nil
						}) {
							Image(systemName: "xmark.circle.fill")
								.foregroundColor(.red)
								.font(.system(size: 24))
								.background(
									Circle()
										.fill(colorScheme == .dark ? Color.black : Color.white)
										.shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
								)
						}
						.offset(x: 8, y: -8)
					}
				} else {
					// Capture the color value before the PhotosPicker closure to avoid Sendable issues
					let strokeColor = colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
					PhotosPicker(selection: $selectedItem, matching: .images) {
						VStack(spacing: 8) {
							Image(systemName: "photo")
								.font(.system(size: 40))
							Text("Select Image")
								.font(.subheadline)
						}
						.foregroundColor(universalAccentColor)
						.frame(maxWidth: 150, maxHeight: 100)
						.padding()
						.background(
							RoundedRectangle(cornerRadius: 8)
								.stroke(strokeColor, lineWidth: 1)
						)
					}
				}

				Spacer()
			}
			Spacer()
		}
		.padding(.horizontal)
	}
}

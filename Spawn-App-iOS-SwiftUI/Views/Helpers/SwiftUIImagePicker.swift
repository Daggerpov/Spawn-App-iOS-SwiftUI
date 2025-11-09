//
//  SwiftUIImagePicker.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2024-05-08.
//

import PhotosUI
import SwiftUI
import SwiftyCrop

struct SwiftUIImagePicker: View {
	@Binding var selectedImage: UIImage?
	@Environment(\.dismiss) private var dismiss
	@State private var photosPickerItem: PhotosPickerItem?
	@State private var originalImage: UIImage?
	@State private var isPresentingPhotoPicker: Bool = true
	@State private var isShowingCropper: Bool = false

	var body: some View {
		ZStack {
			// Background color when no image is selected
			if originalImage == nil {
				Color.black.opacity(0.3)
					.ignoresSafeArea()
					.onTapGesture {
						dismiss()
					}
			} else {
				// Show loading indicator if needed
				Color.clear
			}
		}
		.photosPicker(isPresented: $isPresentingPhotoPicker, selection: $photosPickerItem, matching: .images)
		.onChange(of: photosPickerItem) { _, newItem in
			if newItem != nil {
				Task {
					if let data = try? await newItem?.loadTransferable(type: Data.self),
						let image = UIImage(data: data)
					{
						await MainActor.run {
							self.originalImage = image
							self.isPresentingPhotoPicker = false
							self.isShowingCropper = true
						}
					} else {
						// If loading fails, dismiss the picker
						await MainActor.run {
							dismiss()
						}
					}
				}
			}
		}
		.fullScreenCover(isPresented: $isShowingCropper) {
			if let image = originalImage {
				// Configure SwiftyCrop
				let configuration = SwiftyCropConfiguration(
					maxMagnificationScale: 4.0,
					maskRadius: UIScreen.main.bounds.width * 0.35,
					cropImageCircular: true,
					rotateImage: false,
					zoomSensitivity: 1.0
				)

				SwiftyCropView(
					imageToCrop: image,
					maskShape: .circle,
					configuration: configuration
				) { croppedImage in
					if let croppedImage = croppedImage {
						let finalImage = resizeImageIfNeeded(croppedImage)
						selectedImage = finalImage
					}
					dismiss()
				}
			} else {
				// Fallback
				Color.black
					.onAppear {
						dismiss()
					}
			}
		}
	}

	// Helper method to resize large images
	private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
		let maxDimension: CGFloat = 1000.0  // Set a reasonable max size

		// Check if image needs resizing
		if image.size.width > maxDimension || image.size.height > maxDimension {
			let scale = maxDimension / max(image.size.width, image.size.height)
			let newWidth = image.size.width * scale
			let newHeight = image.size.height * scale
			let targetSize = CGSize(width: newWidth, height: newHeight)

			let renderer = UIGraphicsImageRenderer(size: targetSize)
			let resizedImage = renderer.image { _ in
				image.draw(in: CGRect(origin: .zero, size: targetSize))
			}

			return resizedImage
		}

		return image
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	@Previewable @State var image: UIImage? = nil
	return SwiftUIImagePicker(selectedImage: $image).environmentObject(appCache)
}

//
//  SwiftUIImagePicker.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2024-05-08.
//

import PhotosUI
import SwiftUI
import SwiftyCrop
import UniformTypeIdentifiers

struct SwiftUIImagePicker: View {
	@Binding var selectedImage: UIImage?
	@Environment(\.dismiss) private var dismiss
	@State private var cropSource: CropSource?
	@State private var savedCrop: UIImage?
	@State private var loadingSelection: UUID?
	@State private var showsLoadError = false

	private struct CropSource: Identifiable {
		let id = UUID()
		let image: UIImage
	}

	var body: some View {
		PhotoLibraryPicker(onSelection: loadPhoto, onCancel: { dismiss() })
			.disabled(loadingSelection != nil)
			.overlay {
				if loadingSelection != nil {
					ProgressView("Loading photo…")
						.padding()
						.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
				}
			}
			.fullScreenCover(item: $cropSource, onDismiss: finishCropping) { source in
				SwiftyCropView(
					imageToCrop: source.image,
					maskShape: .circle,
					configuration: SwiftyCropConfiguration(
						maxMagnificationScale: 4.0,
						maskRadius: UIScreen.main.bounds.width * 0.35,
						cropImageCircular: true,
						rotateImage: false,
						// SwiftyCrop multiplies this by 0.1. Match the pinch at 1:1.
						zoomSensitivity: 10.0
					)
				) { croppedImage in
					savedCrop = croppedImage
				}
			}
			.alert("Couldn’t load photo", isPresented: $showsLoadError) {
				Button("OK", role: .cancel) {}
			} message: {
				Text("Try selecting the photo again or choose another one.")
			}
			.onDisappear {
				loadingSelection = nil
			}
	}

	private func loadPhoto(_ provider: NSItemProvider) {
		guard loadingSelection == nil else { return }
		let selection = UUID()
		loadingSelection = selection
		provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
			Task { @MainActor in
				guard loadingSelection == selection else { return }
				loadingSelection = nil
				if let data, let image = UIImage(data: data) {
					cropSource = CropSource(image: image)
				} else {
					showsLoadError = true
				}
			}
		}
	}

	private func finishCropping() {
		guard let savedCrop else { return }
		selectedImage = resizeImageIfNeeded(savedCrop)
		dismiss()
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

// Keep the system picker mounted behind the cropper so Cancel reveals it again.
private struct PhotoLibraryPicker: UIViewControllerRepresentable {
	let onSelection: (NSItemProvider) -> Void
	let onCancel: () -> Void

	func makeUIViewController(context: Context) -> PHPickerViewController {
		var configuration = PHPickerConfiguration()
		configuration.filter = .images
		configuration.selectionLimit = 1
		let picker = PHPickerViewController(configuration: configuration)
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ picker: PHPickerViewController, context: Context) {
		context.coordinator.parent = self
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}

	final class Coordinator: NSObject, PHPickerViewControllerDelegate {
		var parent: PhotoLibraryPicker

		init(parent: PhotoLibraryPicker) {
			self.parent = parent
		}

		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			if let provider = results.first?.itemProvider {
				parent.onSelection(provider)
			} else {
				parent.onCancel()
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	@Previewable @State var image: UIImage? = nil
	return SwiftUIImagePicker(selectedImage: $image).environmentObject(appCache)
}

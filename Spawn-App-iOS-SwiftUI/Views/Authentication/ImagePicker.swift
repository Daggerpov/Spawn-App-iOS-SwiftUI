//
//  ImagePicker.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-16.
//

import SwiftUI
import UIKit
import SwiftyCrop

struct ImagePicker: UIViewControllerRepresentable {
	@Binding var selectedImage: UIImage?
	@Environment(\.presentationMode) private var presentationMode
	@State private var showCropView = false

	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = .photoLibrary
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		let parent: ImagePicker

		init(_ parent: ImagePicker) {
			self.parent = parent
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			if let selectedImage = info[.originalImage] as? UIImage {
				// Dismiss the image picker
				picker.dismiss(animated: true) {
					// Show SwiftyCrop view
					DispatchQueue.main.async {
						self.showSwiftyCropView(for: selectedImage)
					}
				}
			}
		}
		
		private func showSwiftyCropView(for image: UIImage) {
			// Create a new hosting controller for the crop view
			let swiftyCropView = UIHostingController(
				rootView: SwiftyCropContainerView(
					image: image,
					onComplete: { croppedImage in
						self.parent.selectedImage = croppedImage
						self.parent.presentationMode.wrappedValue.dismiss()
					},
					onCancel: {
						self.parent.presentationMode.wrappedValue.dismiss()
					}
				)
			)
			
			// Present the SwiftyCrop view fullscreen
			swiftyCropView.modalPresentationStyle = .fullScreen
			
			// Get the key window using the modern approach
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
				rootViewController.present(swiftyCropView, animated: true)
			}
		}

		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.presentationMode.wrappedValue.dismiss()
		}
	}
}

struct SwiftyCropContainerView: View {
	let image: UIImage
	let onComplete: (UIImage) -> Void
	let onCancel: () -> Void
	
	var body: some View {
		// Create configuration for circle crop
		let configuration = SwiftyCropConfiguration(
			maskRadius: UIScreen.main.bounds.width * 0.4,  // 40% of screen width
			cropImageCircular: true,  // Get circular output image
			rotateImage: true,        // Allow rotation
			zoomSensitivity: 1.0
		)
		
		// Return the SwiftyCrop view
		SwiftyCropView(
			imageToCrop: image,
			maskShape: .circle,
			configuration: configuration
		) { croppedImage in
			// Handle the optional croppedImage
			if let croppedImage = croppedImage {
				onComplete(croppedImage)
			} else {
				// If cropping failed, call cancel
				onCancel()
			}
		}
	}
}

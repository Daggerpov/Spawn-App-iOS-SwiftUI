//
//  ImagePicker.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-16.
//

import SwiftUI
import UIKit
import SwiftyCrop

// This is the main struct that's used throughout the app
struct ImagePicker: UIViewControllerRepresentable {
	@Binding var selectedImage: UIImage?
	@Environment(\.presentationMode) private var presentationMode
	
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
			// Get the image
			guard let imageSelected = info[.originalImage] as? UIImage else {
				picker.dismiss(animated: true)
				return
			}
			
			// Create a direct presented VC for SwiftyCrop
			let cropVC = SwiftyCropperViewController(image: imageSelected) { [weak self] croppedImage in
				guard let self = self else { return }
				
				if let croppedImage = croppedImage {
					// Ensure strong reference to the cropped image and resize if needed
					let finalImage = self.resizeImageIfNeeded(croppedImage)
					
					// Ensure we're on the main thread
					DispatchQueue.main.async {
						print("🖼️ Setting cropped image in parent, size: \(finalImage.size)")
						// Set to nil first to force a refresh, then set the new image
						self.parent.selectedImage = nil
						
						// Small delay to ensure nil change is processed
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
							// Set the image reference directly and force immediate UI update
							self.parent.selectedImage = finalImage
							print("🖼️ Cropped image set successfully, size: \(finalImage.size)")
							
							// Dismiss with slight delay to ensure binding has registered
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
								self.parent.presentationMode.wrappedValue.dismiss()
							}
						}
					}
				} else {
					self.parent.presentationMode.wrappedValue.dismiss()
				}
			}
			
			// Present the crop controller
			picker.dismiss(animated: true) {
				if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
					rootVC.present(cropVC, animated: true)
				}
			}
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.presentationMode.wrappedValue.dismiss()
		}
		
		// Helper method to resize large images
		private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
			let maxDimension: CGFloat = 1000.0 // Set a reasonable max size
			
			// Check if image needs resizing
			if image.size.width > maxDimension || image.size.height > maxDimension {
				print("🔍 Resizing image from \(image.size) to max dimension \(maxDimension)")
				let scale = maxDimension / max(image.size.width, image.size.height)
				let newWidth = image.size.width * scale
				let newHeight = image.size.height * scale
				let newSize = CGSize(width: newWidth, height: newHeight)
				
				UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
				image.draw(in: CGRect(origin: .zero, size: newSize))
				let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
				UIGraphicsEndImageContext()
				
				print("🔍 Resized image to \(resizedImage.size)")
				return resizedImage
			}
			
			return image
		}
	}
}

// UIViewController that embeds SwiftyCrop - more reliable than SwiftUI hosting
class SwiftyCropperViewController: UIViewController {
	private let image: UIImage
	private let completion: (UIImage?) -> Void
	
	init(image: UIImage, completion: @escaping (UIImage?) -> Void) {
		self.image = image
		self.completion = completion
		super.init(nibName: nil, bundle: nil)
		self.modalPresentationStyle = .fullScreen
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Create the configuration
		let configuration = SwiftyCropConfiguration(
			maxMagnificationScale: 5.0,
			maskRadius: view.bounds.width * 0.4,
			cropImageCircular: true,
			rotateImage: true,
			zoomSensitivity: 1.2
		)
		
		// Create SwiftUI crop view
		let cropView = UIHostingController(
			rootView: SwiftyCropView(
				imageToCrop: image,
				maskShape: .circle,
				configuration: configuration
			) { [weak self] croppedImage in
				guard let self = self else { return }
				
				// Ensure strong reference to the cropped image
				if let croppedImage = croppedImage {
					let finalImage = croppedImage
					print("✂️ Image cropped successfully, size: \(finalImage.size)")
					
					// Ensure proper ordering of operations and strong references
					DispatchQueue.main.async {
						self.dismiss(animated: true) {
							DispatchQueue.main.async {
								self.completion(finalImage)
							}
						}
					}
				} else {
					self.dismiss(animated: true) {
						self.completion(nil)
					}
				}
			}
		)
		
		// Add the host controller as a child
		addChild(cropView)
		view.addSubview(cropView.view)
		cropView.view.frame = view.bounds
		cropView.didMove(toParent: self)
	}
}

extension UIApplication {
	var keyWindow: UIWindow? {
		// Get key window for iOS 15+
		return UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap { $0.windows }
			.first { $0.isKeyWindow }
	}
}

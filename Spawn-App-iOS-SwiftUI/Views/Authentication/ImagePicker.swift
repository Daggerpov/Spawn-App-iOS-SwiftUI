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
					// Make a strong reference to the image so it's not deallocated
					let finalImage = croppedImage
					
					// Ensure we're on the main thread
					DispatchQueue.main.async {
						// Set the image reference directly
						self.parent.selectedImage = finalImage
						
						// Print debug info
						print("🖼️ Cropped image set, size: \(finalImage.size)")
						
						// Use a longer delay to ensure binding has time to propagate
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							self.parent.presentationMode.wrappedValue.dismiss()
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
				
				// Ensure we have a strong reference to the cropped image
				if let croppedImage = croppedImage {
					print("✂️ Image cropped, size: \(croppedImage.size)")
					
					// Use DispatchQueue to ensure completion happens after crop view is dismissed
					DispatchQueue.main.async {
						// Dismiss first, then call completion handler to avoid race conditions
						self.dismiss(animated: true) {
							// Ensure the completion is called after dismissal is complete
							DispatchQueue.main.async {
								self.completion(croppedImage)
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

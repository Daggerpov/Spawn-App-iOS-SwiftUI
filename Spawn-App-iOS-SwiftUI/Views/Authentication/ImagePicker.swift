//
//  ImagePicker.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-16.
//

import SwiftUI
import PhotosUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
	@Binding var selectedImage: UIImage?
	@Environment(\.presentationMode) private var presentationMode

	func makeUIViewController(context: Context) -> PHPickerViewController {
		var config = PHPickerConfiguration()
		config.filter = .images
		let picker = PHPickerViewController(configuration: config)
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		let parent: ImagePicker

		init(_ parent: ImagePicker) {
			self.parent = parent
		}

		func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			picker.dismiss(animated: true)

			guard let provider = results.first?.itemProvider else { return }

			if provider.canLoadObject(ofClass: UIImage.self) {
				provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
					// Handle potential errors with iCloud photos
					if let error = error {
						print("Error loading image: \(error.localizedDescription)")
						
						DispatchQueue.main.async {
							// Show fallback to camera/photo library with UIImagePickerController
							self?.showFallbackImagePicker()
						}
						return
					}
					
					DispatchQueue.main.async {
						if let image = image as? UIImage {
							self?.showImageCropper(with: image)
						} else {
							// If image couldn't be loaded as UIImage, show fallback
							self?.showFallbackImagePicker()
						}
					}
				}
			}
		}

		func showImageCropper(with image: UIImage) {
			let cropViewController = CropImageViewController(image: image) { [weak self] croppedImage in
				DispatchQueue.main.async {
					self?.parent.selectedImage = croppedImage
				}
			}

			// Find the current view controller to present from
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			   let rootVC = windowScene.windows.first?.rootViewController {
				var currentVC = rootVC
				while let presentedVC = currentVC.presentedViewController {
					currentVC = presentedVC
				}
				currentVC.present(cropViewController, animated: true)
			}
		}

		// Add a fallback method using UIImagePickerController
		func showFallbackImagePicker() {
			let alertController = UIAlertController(
				title: "Cloud Photo Error",
				message: "There was an issue accessing your iCloud photo. Would you like to choose from your device or take a new photo?",
				preferredStyle: .alert
			)
			
			alertController.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
				self?.showImagePickerController(sourceType: .photoLibrary)
			})
			
			alertController.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
				self?.showImagePickerController(sourceType: .camera)
			})
			
			alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
			
			// Find the current view controller to present from
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			   let rootVC = windowScene.windows.first?.rootViewController {
				var currentVC = rootVC
				while let presentedVC = currentVC.presentedViewController {
					currentVC = presentedVC
				}
				currentVC.present(alertController, animated: true)
			}
		}
		
		func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
			// Check if the source type is available
			guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
				print("Source type \(sourceType) is not available")
				return
			}
			
			let picker = UIImagePickerController()
			picker.sourceType = sourceType
			picker.delegate = self
			picker.allowsEditing = true
			
			// Find the current view controller to present from
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			   let rootVC = windowScene.windows.first?.rootViewController {
				var currentVC = rootVC
				while let presentedVC = currentVC.presentedViewController {
					currentVC = presentedVC
				}
				currentVC.present(picker, animated: true)
			}
		}
		
		// UIImagePickerControllerDelegate methods
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			picker.dismiss(animated: true)
			
			// Use edited image if available, otherwise use original
			if let editedImage = info[.editedImage] as? UIImage {
				self.showImageCropper(with: editedImage)
			} else if let originalImage = info[.originalImage] as? UIImage {
				self.showImageCropper(with: originalImage)
			}
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			picker.dismiss(animated: true)
		}
	}
}

class CropImageViewController: UIViewController {
	private let imageView = UIImageView()
	private let originalImage: UIImage
	private let completion: (UIImage) -> Void

	private let cropOverlayView = UIView()
	private let cropFrameView = UIView()

	init(image: UIImage, completion: @escaping (UIImage) -> Void) {
		self.originalImage = image
		self.completion = completion
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
	}

	private func setupUI() {
		view.backgroundColor = .black

		// Setup image view
		imageView.contentMode = .scaleAspectFit
		imageView.image = originalImage
		imageView.frame = view.bounds
		view.addSubview(imageView)

		// Setup crop overlay
		cropOverlayView.frame = view.bounds
		cropOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		view.addSubview(cropOverlayView)

		// Create circular crop frame
		let minDimension = min(view.bounds.width, view.bounds.height) * 0.8
		let cropSize = CGSize(width: minDimension, height: minDimension)
		cropFrameView.frame = CGRect(
			x: (view.bounds.width - cropSize.width) / 2,
			y: (view.bounds.height - cropSize.height) / 2,
			width: cropSize.width,
			height: cropSize.height
		)
		cropFrameView.layer.cornerRadius = minDimension / 2
		cropFrameView.layer.borderColor = UIColor.white.cgColor
		cropFrameView.layer.borderWidth = 2
		view.addSubview(cropFrameView)

		// Cut the circular hole in the overlay
		let path = UIBezierPath(rect: cropOverlayView.bounds)
		let circlePath = UIBezierPath(ovalIn: cropFrameView.frame)
		path.append(circlePath)
		path.usesEvenOddFillRule = true

		let maskLayer = CAShapeLayer()
		maskLayer.path = path.cgPath
		maskLayer.fillRule = .evenOdd
		cropOverlayView.layer.mask = maskLayer

		// Add buttons
		let buttonStack = UIStackView()
		buttonStack.axis = .horizontal
		buttonStack.distribution = .fillEqually
		buttonStack.spacing = 20

		let cancelButton = UIButton(type: .system)
		cancelButton.setTitle("Cancel", for: .normal)
		cancelButton.setTitleColor(.white, for: .normal)
		cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

		let doneButton = UIButton(type: .system)
		doneButton.setTitle("Done", for: .normal)
		doneButton.setTitleColor(.white, for: .normal)
		doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

		buttonStack.addArrangedSubview(cancelButton)
		buttonStack.addArrangedSubview(doneButton)

		view.addSubview(buttonStack)
		buttonStack.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
			buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
			buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
			buttonStack.heightAnchor.constraint(equalToConstant: 50)
		])
	}

	@objc private func cancelTapped() {
		dismiss(animated: true)
	}

	@objc private func doneTapped() {
		let scaledCropFrame = convertCropFrameToImageCoordinates()
		if let croppedImage = cropImage(with: scaledCropFrame) {
			completion(croppedImage)
		}
		dismiss(animated: true)
	}

	private func convertCropFrameToImageCoordinates() -> CGRect {
		// Convert the crop frame view's frame to the image view's coordinate space
		let cropFrameInImageView = view.convert(cropFrameView.frame, to: imageView)

		// Get the image's displayed frame within the image view
		let imageViewSize = imageView.frame.size
		let imageSize = originalImage.size

		let imageAspect = imageSize.width / imageSize.height
		let viewAspect = imageViewSize.width / imageViewSize.height

		var imageDisplayRect = CGRect.zero

		if imageAspect > viewAspect {
			// Image is wider than view
			let height = imageViewSize.width / imageAspect
			let yOffset = (imageViewSize.height - height) / 2
			imageDisplayRect = CGRect(x: 0, y: yOffset, width: imageViewSize.width, height: height)
		} else {
			// Image is taller than view
			let width = imageViewSize.height * imageAspect
			let xOffset = (imageViewSize.width - width) / 2
			imageDisplayRect = CGRect(x: xOffset, y: 0, width: width, height: imageViewSize.height)
		}

		// Convert crop frame from image view coordinates to image coordinates
		let scaleX = imageSize.width / imageDisplayRect.width
		let scaleY = imageSize.height / imageDisplayRect.height

		let imageX = (cropFrameInImageView.origin.x - imageDisplayRect.origin.x) * scaleX
		let imageY = (cropFrameInImageView.origin.y - imageDisplayRect.origin.y) * scaleY
		let imageWidth = cropFrameInImageView.width * scaleX
		let imageHeight = cropFrameInImageView.height * scaleY

		return CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
	}

	private func cropImage(with rect: CGRect) -> UIImage? {
		let imageSize = originalImage.size
		let scale = originalImage.scale

		// Ensure the cropping rect is within image bounds
		let safeCropRect = CGRect(
			x: max(0, rect.origin.x),
			y: max(0, rect.origin.y),
			width: min(rect.width, imageSize.width - rect.origin.x),
			height: min(rect.height, imageSize.height - rect.origin.y)
		)

		// Scale crop rect to handle image scale
		let scaledCropRect = CGRect(
			x: safeCropRect.origin.x * scale,
			y: safeCropRect.origin.y * scale,
			width: safeCropRect.width * scale,
			height: safeCropRect.height * scale
		)

		// Perform the crop
		guard let cgImage = originalImage.cgImage?.cropping(to: scaledCropRect) else {
			return nil
		}

		// Create a circular image
		let ciImage = CIImage(cgImage: cgImage)
		let filter = CIFilter(name: "CIRadialGradientMask")

		let size = CGSize(width: cgImage.width, height: cgImage.height)
		let smallerSide = min(size.width, size.height)
		let radius = smallerSide / 2

		filter?.setValue(ciImage, forKey: kCIInputImageKey)
		filter?.setValue(CIVector(x: radius, y: radius), forKey: "inputCenter")
		filter?.setValue(radius, forKey: "inputRadius0")
		filter?.setValue(0, forKey: "inputRadius1")

		// Create a circular image
		let outputImage = UIImage(cgImage: cgImage, scale: scale, orientation: originalImage.imageOrientation)

		return outputImage
	}
}

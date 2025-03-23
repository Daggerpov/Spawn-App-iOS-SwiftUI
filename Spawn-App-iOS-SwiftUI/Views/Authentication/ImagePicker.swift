//
//  ImagePicker.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-16.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
	@Binding var selectedImage: UIImage?
	@Environment(\.presentationMode) private var presentationMode

	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = .photoLibrary
		picker.delegate = context.coordinator
		picker.allowsEditing = true // Use the built-in editor for basic crop
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
			// Get the edited image if available, otherwise use the original
			if let editedImage = info[.editedImage] as? UIImage {
				makeCircularImage(editedImage)
			} else if let originalImage = info[.originalImage] as? UIImage {
				makeCircularImage(originalImage)
			}
			
			// Dismiss the picker
			picker.dismiss(animated: true)
		}

		private func makeCircularImage(_ image: UIImage) {
			let originalImage = image
			
			// Create a square cropping rectangle for the circular mask
			let sideLength = min(originalImage.size.width, originalImage.size.height)
			let xOffset = (originalImage.size.width - sideLength) / 2
			let yOffset = (originalImage.size.height - sideLength) / 2
			let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)
			
			// Crop the image to a square
			guard let squareImage = cropImage(originalImage, toRect: cropRect) else { return }
			
			// Create a circular mask
			let circularImage = maskToCircle(image: squareImage)
			
			// Update the binding
			DispatchQueue.main.async {
				self.parent.selectedImage = circularImage
				self.parent.presentationMode.wrappedValue.dismiss()
			}
		}

		private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
			// Scale crop rect to account for image scale
			let scale = image.scale
			let scaledRect = CGRect(
				x: rect.origin.x * scale,
				y: rect.origin.y * scale,
				width: rect.width * scale,
				height: rect.height * scale
			)
			
			guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
				return nil
			}
			
			return UIImage(
				cgImage: cgImage,
				scale: image.scale,
				orientation: image.imageOrientation
			)
		}

		private func maskToCircle(image: UIImage) -> UIImage {
			let imageSize = image.size
			let dimension = min(imageSize.width, imageSize.height)
			let circleRect = CGRect(
				x: 0,
				y: 0,
				width: dimension,
				height: dimension
			)
			
			UIGraphicsBeginImageContextWithOptions(circleRect.size, false, image.scale)
			defer { UIGraphicsEndImageContext() }
			
			let context = UIGraphicsGetCurrentContext()!
			context.saveGState()
			
			// Create and add circle path to context
			let circlePath = UIBezierPath(ovalIn: circleRect)
			circlePath.addClip()
			
			// Draw the image
			image.draw(in: circleRect)
			
			context.restoreGState()
			
			// Get the masked image
			guard let maskedImage = UIGraphicsGetImageFromCurrentImageContext() else {
				return image
			}
			
			return maskedImage
		}

		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.presentationMode.wrappedValue.dismiss()
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

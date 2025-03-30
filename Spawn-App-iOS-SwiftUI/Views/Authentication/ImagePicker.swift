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
		picker.allowsEditing = false // Disable built-in editor to avoid the rectangular crop step
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
		let parent: ImagePicker
		let profileImageSize: CGFloat = 150

		init(_ parent: ImagePicker) {
			self.parent = parent
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			// Get the original image directly, skip the edited image step
			if let originalImage = info[.originalImage] as? UIImage {
				// Show our custom crop view controller
				presentCropViewController(for: originalImage, from: picker)
			}
			
			// Don't dismiss yet - we'll do that after cropping
		}
		
		private func presentCropViewController(for image: UIImage, from presenter: UIViewController) {
			let cropViewController = CropImageViewController(image: image, profileImageSize: profileImageSize) { [weak self] croppedImage in
				DispatchQueue.main.async {
					self?.parent.selectedImage = croppedImage
					self?.parent.presentationMode.wrappedValue.dismiss()
				}
			}
			
			presenter.present(cropViewController, animated: true)
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
	private let profileImageSize: CGFloat

	private let cropOverlayView = UIView()
	private let cropFrameView = UIView()
    
    // Add variables for tracking image movement
    private var initialImageFrame: CGRect = .zero
    private var currentImageOffset: CGPoint = .zero
    private var lastPanPoint: CGPoint = .zero

	init(image: UIImage, profileImageSize: CGFloat, completion: @escaping (UIImage) -> Void) {
		self.originalImage = image
		self.profileImageSize = profileImageSize
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
		imageView.isUserInteractionEnabled = true // Enable user interaction
		view.addSubview(imageView)
        
        // Save initial image frame for panning calculations
        initialImageFrame = getImageFrameInImageView()
        
        // Add pan gesture recognizer to allow image movement
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        imageView.addGestureRecognizer(panGesture)

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
			// Final step: resize to profile image size and ensure it's circular
			let finalImage = createFinalCircularImage(from: croppedImage)
			completion(finalImage)
		}
		dismiss(animated: true)
	}

	// Get the actual image frame within the UIImageView
	private func getImageFrameInImageView() -> CGRect {
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
		
		return imageDisplayRect
	}
    
    // Handle pan gesture for image movement
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: imageView)
        
        switch gesture.state {
        case .began:
            lastPanPoint = .zero
        case .changed:
            // Calculate the drag delta from the last point
            let deltaX = translation.x - lastPanPoint.x
            let deltaY = translation.y - lastPanPoint.y
            
            // Update last point
            lastPanPoint = translation
            
            // Update current offset
            currentImageOffset.x += deltaX
            currentImageOffset.y += deltaY
            
            // Apply constraints to make sure we don't move too far
            applyImagePositionConstraints()
            
            // Update the image position
            updateImageViewTransform()
        case .ended, .cancelled:
            // Final constraint check
            applyImagePositionConstraints()
        default:
            break
        }
    }
    
    // Apply constraints to prevent moving the image too far from the crop area
    private func applyImagePositionConstraints() {
        let imageFrame = getImageFrameInImageView()
        let cropFrame = cropFrameView.frame
        
        // Calculate the maximum offset based on image and crop sizes
        // This ensures the image can't be moved so far that the crop area would be empty
        let maxOffsetX = max(0, (imageFrame.width - cropFrame.width) / 2)
        let maxOffsetY = max(0, (imageFrame.height - cropFrame.height) / 2)
        
        // Constrain horizontal movement
        currentImageOffset.x = max(-maxOffsetX, min(maxOffsetX, currentImageOffset.x))
        
        // Constrain vertical movement
        currentImageOffset.y = max(-maxOffsetY, min(maxOffsetY, currentImageOffset.y))
    }
    
    // Update the image view's transform based on current offset
    private func updateImageViewTransform() {
        imageView.transform = CGAffineTransform(translationX: currentImageOffset.x, y: currentImageOffset.y)
    }

	private func convertCropFrameToImageCoordinates() -> CGRect {
		// Convert the crop frame view's frame to the image view's coordinate space
		let cropFrameInImageView = view.convert(cropFrameView.frame, to: imageView)

		// Get the image's displayed frame within the image view
		let imageViewSize = imageView.frame.size
		let imageSize = originalImage.size

		let imageAspect = imageSize.width / imageSize.height
		let viewAspect = imageViewSize.width / imageViewSize.height

		var imageDisplayRect = getImageFrameInImageView()

        // Adjust coordinates based on the current pan offset
        imageDisplayRect.origin.x -= currentImageOffset.x
        imageDisplayRect.origin.y -= currentImageOffset.y

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

		return UIImage(cgImage: cgImage, scale: scale, orientation: originalImage.imageOrientation)
	}
	
	private func createFinalCircularImage(from image: UIImage) -> UIImage {
		// Create final image with exact profile size dimensions
		let finalSize = CGSize(width: profileImageSize, height: profileImageSize)
		UIGraphicsBeginImageContextWithOptions(finalSize, false, 0)
		defer { UIGraphicsEndImageContext() }
		
		// Create circular clipping path
		let context = UIGraphicsGetCurrentContext()!
		context.addEllipse(in: CGRect(origin: .zero, size: finalSize))
		context.clip()
		
		// Draw the image inside the circular clipping path
		image.draw(in: CGRect(origin: .zero, size: finalSize))
		
		// Get the final circular image
		if let circularImage = UIGraphicsGetImageFromCurrentImageContext() {
			return circularImage
		}
		
		return image
	}
}

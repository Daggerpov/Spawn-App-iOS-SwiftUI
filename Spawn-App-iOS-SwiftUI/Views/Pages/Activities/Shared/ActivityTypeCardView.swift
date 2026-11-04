//
//  ActivityTypeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import SwiftUI

struct ActivityTypeCardView: View {
	var activityType: ActivityTypeDTO
	var onTap: ((ActivityTypeDTO) -> Void)? = nil
	@Environment(\.colorScheme) private var colorScheme

	// Animation states for 3D effect
	@State private var isPressed = false
	@State private var scale: CGFloat = 1.0

	// Title sizing: long words shrink to fit instead of breaking mid-word ("Basket / ball")
	private let titleFontSize: CGFloat = 16
	private let minTitleFontSize: CGFloat = 9
	@State private var titleWidth: CGFloat = 0

	// Adaptive background color (solid colors instead of gradients)
	private var adaptiveBackgroundColor: Color {
		switch colorScheme {
		case .dark:
			return Color(hex: "#2C2C2C")
		case .light:
			return Color(hex: figmaTypeButtonHex)
		@unknown default:
			return Color(hex: figmaTypeButtonHex)
		}
	}

	// Adaptive text color
	private var adaptiveTextColor: Color {
		switch colorScheme {
		case .dark:
			return Color.white
		case .light:
			return Color(hex: figmaNavyHex)
		@unknown default:
			return Color(hex: figmaNavyHex)
		}
	}

	/// Largest font size (up to `titleFontSize`) at which the title's longest word fits on one line.
	/// Multi-word titles still wrap between words onto the second line.
	private var fittedTitleFontSize: CGFloat {
		let font =
			UIFont(name: "Onest-SemiBold", size: titleFontSize)
			?? .systemFont(ofSize: titleFontSize, weight: .semibold)
		let longestWordWidth =
			activityType.title
			.split(separator: " ")
			.map { String($0).size(withAttributes: [.font: font]).width }
			.max() ?? 0
		guard titleWidth > 0, longestWordWidth > titleWidth else { return titleFontSize }
		// Round down to half points so the word still fits after text layout rounding
		return max(floor(titleFontSize * titleWidth / longestWordWidth * 2) / 2, minTitleFontSize)
	}

	var body: some View {
		VStack(spacing: 4) {
			ActivityTypeIconView(emoji: activityType.icon, size: 34)
			Text(activityType.title)
				.font(.onestSemiBold(size: fittedTitleFontSize))
				.foregroundColor(adaptiveTextColor)
				.lineLimit(2)
				.truncationMode(.tail)
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
				.onGeometryChange(for: CGFloat.self) { proxy in
					proxy.size.width
				} action: { width in
					titleWidth = width
				}
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 8)
		.frame(maxWidth: .infinity, minHeight: 115)
		.background(
			// Figma Activity Type Button: #EDEFF6 with a soft inner shadow (#0000000D, y -4, blur 8)
			RoundedRectangle(cornerRadius: 12)
				.fill(adaptiveBackgroundColor.shadow(.inner(color: .black.opacity(0.05), radius: 4, x: 0, y: -4)))
		)
		.animation(.easeInOut(duration: 0.15), value: scale)
		.animation(.easeInOut(duration: 0.15), value: isPressed)
		.onTapGesture {
			// Haptic feedback
			let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
			impactGenerator.impactOccurred()

			if let onTap = onTap {
				print("🔘 ActivityTypeCardView '\(activityType.title)' button tapped")
				onTap(activityType)
			} else {
				print("❌ ActivityTypeCardView '\(activityType.title)' button tapped but onTap is nil")
			}
		}
		.gesture(
			DragGesture(minimumDistance: 0)
				.onChanged { _ in
					if !isPressed {
						isPressed = true
						scale = 0.95

						// Haptic feedback for press down
						let selectionGenerator = UISelectionFeedbackGenerator()
						selectionGenerator.selectionChanged()
					}
				}
				.onEnded { _ in
					isPressed = false
					scale = 1.0
				}
		)
	}
}

/// Shows an activity type's emoji cropped to its visible pixels and scaled to fill a square, so all
/// icons look the same size. Emoji fonts pad some glyphs (e.g. 🏃) far more than others (e.g. 🏀),
/// which made them look smaller at the same font size.
private struct ActivityTypeIconView: View {
	let emoji: String
	let size: CGFloat

	private static var trimmedImages: [String: UIImage] = [:]

	var body: some View {
		Group {
			if let image = Self.trimmedImage(for: emoji) {
				Image(uiImage: image)
					.resizable()
					.scaledToFit()
			} else {
				Text(emoji)
					.font(.system(size: size))
			}
		}
		.frame(width: size, height: size)
		.accessibilityHidden(true)
	}

	private static func trimmedImage(for emoji: String) -> UIImage? {
		if let cached = trimmedImages[emoji] {
			return cached
		}
		// Render large so the cropped bitmap stays sharp when scaled down
		let text = NSAttributedString(string: emoji, attributes: [.font: UIFont.systemFont(ofSize: 120)])
		let canvasSize = text.size()
		guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }
		let format = UIGraphicsImageRendererFormat()
		format.scale = 1
		let rendered = UIGraphicsImageRenderer(size: canvasSize, format: format).image { _ in
			text.draw(at: .zero)
		}
		guard let cgImage = rendered.cgImage,
			let visibleRect = visiblePixelRect(of: cgImage),
			let cropped = cgImage.cropping(to: visibleRect)
		else { return nil }
		let image = UIImage(cgImage: cropped)
		trimmedImages[emoji] = image
		return image
	}

	/// Bounding rect (top-left origin, in pixels) of the visible pixels, ignoring near-transparent edges
	private static func visiblePixelRect(of image: CGImage) -> CGRect? {
		let width = image.width
		let height = image.height
		var pixels = [UInt8](repeating: 0, count: width * height * 4)
		let didDraw = pixels.withUnsafeMutableBytes { buffer -> Bool in
			guard
				let context = CGContext(
					data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
					bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
					bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
			else { return false }
			context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
			return true
		}
		guard didDraw else { return nil }

		var minX = width
		var minY = height
		var maxX = -1
		var maxY = -1
		for y in 0..<height {
			for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 10 {
				minX = min(minX, x)
				maxX = max(maxX, x)
				minY = min(minY, y)
				maxY = max(maxY, y)
			}
		}
		guard maxX >= minX, maxY >= minY else { return nil }
		return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
	}
}

#if DEBUG
	struct ActivityTypeCardView_Previews: PreviewProvider {
		static var previews: some View {
			let mockActivityType = ActivityTypeDTO.mockActiveActivityType
			VStack {
				ActivityTypeCardView(activityType: mockActivityType)
					.padding()
					.previewLayout(.sizeThatFits)
					.preferredColorScheme(.light)

				ActivityTypeCardView(activityType: mockActivityType)
					.padding()
					.previewLayout(.sizeThatFits)
					.preferredColorScheme(.dark)
			}
		}
	}
#endif

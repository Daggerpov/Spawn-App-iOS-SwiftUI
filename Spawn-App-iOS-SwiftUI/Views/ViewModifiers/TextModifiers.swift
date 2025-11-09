import SwiftUI

// MARK: - View Extensions
extension View {
	func onestHeadline() -> some View {
		self.modifier(HeadlineModifier())
	}

	func onestSubheadline() -> some View {
		self.modifier(SubheadlineModifier())
	}

	func onestSemiBold(size: CGFloat = 16) -> some View {
		self.modifier(SemiboldTextModifier(size: size))
	}

	func onestBody() -> some View {
		self.modifier(BodyModifier())
	}

	func onestCaption() -> some View {
		self.modifier(CaptionModifier())
	}

	func onestSmallText() -> some View {
		self.modifier(SmallTextModifier())
	}
}

@available(iOS 17.0, *)
#Preview {
	VStack(alignment: .leading, spacing: 16) {
		Text("Headline Text")
			.onestHeadline()
			.foregroundColor(.primary)

		Text("Subheadline Text")
			.onestSubheadline()
			.foregroundColor(.primary)

		Text("Semibold Text (16pt)")
			.onestSemiBold()
			.foregroundColor(.primary)

		Text("Semibold Text (20pt)")
			.onestSemiBold(size: 20)
			.foregroundColor(.primary)

		Text("Body Text")
			.onestBody()
			.foregroundColor(.primary)

		Text("Caption Text")
			.onestCaption()
			.foregroundColor(.secondary)

		Text("Small Text")
			.onestSmallText()
			.foregroundColor(.secondary)
	}
	.padding()
}

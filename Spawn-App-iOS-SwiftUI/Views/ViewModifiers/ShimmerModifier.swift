import SwiftUI

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
	@State private var phase: CGFloat = 0

	func body(content: Content) -> some View {
		content
			.overlay(
				GeometryReader { geometry in
					Color.white
						.opacity(0.3)
						.mask(
							Rectangle()
								.fill(
									LinearGradient(
										gradient: Gradient(colors: [.clear, .white.opacity(0.7), .clear]),
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.frame(width: geometry.size.width * 2)
								.offset(x: -geometry.size.width)
								.offset(x: phase * geometry.size.width)
						)
				}
			)
			.onAppear {
				withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
					phase = 1
				}
			}
	}
}

// MARK: - View Extension
extension View {
	func shimmering() -> some View {
		modifier(ShimmerModifier())
	}
}

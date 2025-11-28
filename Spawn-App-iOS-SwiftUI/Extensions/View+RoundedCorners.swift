import SwiftUI

extension View {
	/// Applies rounded corners to specific corners of the view
	/// - Parameters:
	///   - radius: The corner radius to apply
	///   - corners: The specific corners to round (e.g., [.topLeft, .topRight])
	/// - Returns: A view with the specified corners rounded
	func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
		clipShape(RoundedCorner(radius: radius, corners: corners))
	}
}

/// A custom shape that allows rounding specific corners
struct RoundedCorner: Shape {
	var radius: CGFloat = .infinity
	var corners: UIRectCorner = .allCorners

	func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(
			roundedRect: rect,
			byRoundingCorners: corners,
			cornerRadii: CGSize(width: radius, height: radius)
		)
		return Path(path.cgPath)
	}
}

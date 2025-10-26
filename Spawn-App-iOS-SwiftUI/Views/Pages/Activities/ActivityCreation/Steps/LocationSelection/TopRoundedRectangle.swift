import SwiftUI

// Custom shape for top-rounded rectangles (iOS < 16 compatibility)
struct TopRoundedRectangle: Shape {
	let radius: CGFloat

	func path(in rect: CGRect) -> Path {
		var path = Path()

		path.move(to: CGPoint(x: 0, y: rect.maxY))
		path.addLine(to: CGPoint(x: 0, y: radius))
		path.addArc(
			center: CGPoint(x: radius, y: radius),
			radius: radius,
			startAngle: .radians(.pi),
			endAngle: .radians(.pi * 1.5),
			clockwise: false
		)
		path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
		path.addArc(
			center: CGPoint(x: rect.maxX - radius, y: radius),
			radius: radius,
			startAngle: .radians(.pi * 1.5),
			endAngle: .radians(0),
			clockwise: false
		)
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		path.closeSubpath()

		return path
	}
}


//
//  ActivityGradient.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

/// Figma "Gradients Sample" (Home Feed page, node 2802:2327): every activity color is a radial
/// gradient that goes from a light tint at its origin to a deep shade at the far edge.
/// Activities are still assigned a flat base color (see `ActivityColorService`); this maps that
/// base color to its gradient so cards and drawers can share it.
enum ActivityGradient {
	/// Gradient stops keyed by the activity's base color hex.
	private static let stopsByBaseHex: [String: [Gradient.Stop]] = [
		// Red
		activityRedHexCode: [
			.init(color: Color(hex: "#FB6C6A"), location: 0),
			.init(color: Color(hex: "#CA4161"), location: 0.5),
			.init(color: Color(hex: "#B12B5C"), location: 0.75),
			.init(color: Color(hex: "#981657"), location: 1),
		],
		// Pink to purple
		activityPinkHexCode: [
			.init(color: Color(hex: "#FB6AC6"), location: 0),
			.init(color: Color(hex: "#CE55BA"), location: 0.25),
			.init(color: Color(hex: "#A140AF"), location: 0.5),
			.init(color: Color(hex: "#742BA4"), location: 0.75),
			.init(color: Color(hex: "#481698"), location: 1),
		],
		// Green
		activityGreenHexCode: [
			.init(color: Color(hex: "#7DF883"), location: 0),
			.init(color: Color(hex: "#63DA75"), location: 0.25),
			.init(color: Color(hex: "#49BC66"), location: 0.5),
			.init(color: Color(hex: "#2E9E57"), location: 0.75),
			.init(color: Color(hex: "#148049"), location: 1),
		],
		// Cyan to indigo
		activityBlueHexCode: [
			.init(color: Color(hex: "#6AD2FB"), location: 0),
			.init(color: Color(hex: "#5DA3E2"), location: 0.25),
			.init(color: Color(hex: "#4F74CA"), location: 0.5),
			.init(color: Color(hex: "#4245B1"), location: 0.75),
			.init(color: Color(hex: "#3B2DA4"), location: 0.875),
			.init(color: Color(hex: "#341698"), location: 1),
		],
	]

	/// The gradient stops for an activity's base color. Colors outside the palette (backend color
	/// codes, older cached colors) use the gradient of the nearest palette color, so no activity
	/// surface ever falls back to a flat fill.
	static func stops(for baseColor: Color) -> [Gradient.Stop] {
		let hex = baseColor.hex.uppercased()
		if let stops = stopsByBaseHex[hex] {
			return stops
		}
		return stopsByBaseHex[nearestPaletteHex(to: hex)] ?? []
	}

	/// The palette hex closest to `hex` by RGB distance.
	private static func nearestPaletteHex(to hex: String) -> String {
		let target = rgb(hex)
		return activityColorHexCodes.min { lhs, rhs in
			distance(rgb(lhs), target) < distance(rgb(rhs), target)
		} ?? activityBlueHexCode
	}

	private static func rgb(_ hex: String) -> (Int, Int, Int) {
		let value = Int(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
		return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
	}

	private static func distance(_ a: (Int, Int, Int), _ b: (Int, Int, Int)) -> Int {
		let dr = a.0 - b.0
		let dg = a.1 - b.1
		let db = a.2 - b.2
		return dr * dr + dg * dg + db * db
	}

	/// Location pill fill in the activity drawer (Figma node 2805:5432): a left-to-right blend from
	/// a deep shade of the activity color to its lightest tint.
	static func pillGradient(for baseColor: Color) -> LinearGradient {
		let stops = stops(for: baseColor)
		let deep = stops.first(where: { $0.location == 0.75 })?.color ?? stops.last?.color ?? baseColor
		let light = stops.first?.color ?? baseColor
		return LinearGradient(colors: [deep, light], startPoint: .leading, endPoint: .trailing)
	}

	/// Activity card fill (Figma node 2802:4649): radiates from the bottom-right corner and reaches
	/// the darkest stop at the top-left corner.
	static func cardGradient(for baseColor: Color, size: CGSize) -> RadialGradient {
		RadialGradient(
			stops: stops(for: baseColor),
			center: .bottomTrailing,
			startRadius: 0,
			endRadius: max(hypot(size.width, size.height), 1)
		)
	}
}

/// Rounded activity-card background: Figma's radial gradient plus the inner white glow.
/// Used by every activity surface (feed cards, profile cards, past-activity cards, calendar cells).
struct ActivityCardGradientBackground: View {
	let color: Color
	var cornerRadius: CGFloat = 12
	/// Figma's inner glow is drawn for a full-size card; small tiles scale it down.
	var innerGlowRadius: CGFloat = 8

	var body: some View {
		GeometryReader { geometry in
			RoundedRectangle(cornerRadius: cornerRadius)
				.fill(
					ActivityGradient.cardGradient(for: color, size: geometry.size)
						// Figma "inner/16i": #FFFFFF40, y -4, blur 16
						.shadow(
							.inner(color: .white.opacity(0.25), radius: innerGlowRadius, x: 0, y: -innerGlowRadius / 2))
				)
		}
	}
}

/// Activity drawer background (Figma node 2805:5412): the same gradient, radiating from the bottom
/// center up to the top. Shared by the drawer, its chatroom and the participants list.
struct ActivityDrawerGradientBackground: View {
	let color: Color

	var body: some View {
		// Figma's ellipse has the drawer's full width and height as its radii, centered on the
		// bottom edge. An elliptical gradient's radius fraction is relative to the view's size,
		// so 1 matches that.
		EllipticalGradient(
			stops: ActivityGradient.stops(for: color),
			center: .bottom,
			startRadiusFraction: 0,
			endRadiusFraction: 1
		)
	}
}

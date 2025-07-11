//
//  ColorHelper.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

extension Color {
	init(hex: String) {
		let scanner = Scanner(string: hex)
		_ = scanner.scanString("#")
		var rgbValue: UInt64 = 0
		scanner.scanHexInt64(&rgbValue)
		let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
		let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
		let blue = Double(rgbValue & 0x0000FF) / 255.0
		self.init(red: red, green: green, blue: blue)
	}
	var hex: String {
		guard let components = cgColor?.components, components.count >= 3 else {
			return "#000000"
		}
		let r = Float(components.indices.contains(0) ? components[0] : 0)
		let g = Float(components.indices.contains(1) ? components[1] : 0)
		let b = Float(components.indices.contains(2) ? components[2] : 0)
		return String(
			format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255),
			lroundf(b * 255))
	}
}

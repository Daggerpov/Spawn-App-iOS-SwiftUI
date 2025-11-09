import Foundation
import SwiftUI

enum AppColorScheme: String, CaseIterable {
	case system = "system"
	case light = "light"
	case dark = "dark"

	var displayName: String {
		switch self {
		case .system:
			return "System"
		case .light:
			return "Light"
		case .dark:
			return "Dark"
		}
	}

	var colorScheme: ColorScheme? {
		switch self {
		case .system:
			return nil
		case .light:
			return .light
		case .dark:
			return .dark
		}
	}

	var systemIcon: String {
		switch self {
		case .system:
			return "gear"
		case .light:
			return "sun.max"
		case .dark:
			return "moon"
		}
	}
}

class ThemeService: ObservableObject {
	static let shared = ThemeService()

	@Published var colorScheme: AppColorScheme = .system {
		didSet {
			UserDefaults.standard.set(colorScheme.rawValue, forKey: "app_color_scheme")
		}
	}

	private init() {
		// Load saved preference
		if let savedScheme = UserDefaults.standard.string(forKey: "app_color_scheme"),
			let scheme = AppColorScheme(rawValue: savedScheme)
		{
			self.colorScheme = scheme
		}
	}

	func setColorScheme(_ scheme: AppColorScheme) {
		colorScheme = scheme
	}

	// MARK: - Dynamic Colors

	func backgroundColor(for colorScheme: ColorScheme) -> Color {
		switch colorScheme {
		case .light:
			return Color(hex: "#FFFFFF")
		case .dark:
			return Color(hex: "#1C1C1E")  // iOS system background dark color
		@unknown default:
			return Color(hex: "#FFFFFF")
		}
	}

	func accentColor(for colorScheme: ColorScheme) -> Color {
		switch colorScheme {
		case .light:
			return Color(hex: "#1D1D1D")
		case .dark:
			return Color(hex: "#FFFFFF")
		@unknown default:
			return Color(hex: "#1D1D1D")
		}
	}

	func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
		switch colorScheme {
		case .light:
			return Color(hex: "#8E8484")
		case .dark:
			return Color(hex: "#A8A8A8")
		@unknown default:
			return Color(hex: "#8E8484")
		}
	}

	func cardBackgroundColor(for colorScheme: ColorScheme) -> Color {
		switch colorScheme {
		case .light:
			return Color.white.opacity(0.5)
		case .dark:
			return Color.black.opacity(0.3)
		@unknown default:
			return Color.white.opacity(0.5)
		}
	}

	func borderColor(for colorScheme: ColorScheme) -> Color {
		switch colorScheme {
		case .light:
			return Color.gray
		case .dark:
			return Color.gray.opacity(0.3)
		@unknown default:
			return Color.gray
		}
	}

	func placeholderTextColor(for colorScheme: ColorScheme) -> Color {
		switch colorScheme {
		case .light:
			return Color(hex: "#B0AFAF")
		case .dark:
			return Color(hex: "#6B6B6B")
		@unknown default:
			return Color(hex: "#B0AFAF")
		}
	}
}

// MARK: - Dynamic Color Extensions
extension Color {
	static func dynamicBackground(_ colorScheme: ColorScheme) -> Color {
		return ThemeService.shared.backgroundColor(for: colorScheme)
	}

	static func dynamicAccent(_ colorScheme: ColorScheme) -> Color {
		return ThemeService.shared.accentColor(for: colorScheme)
	}

	static func dynamicSecondaryText(_ colorScheme: ColorScheme) -> Color {
		return ThemeService.shared.secondaryTextColor(for: colorScheme)
	}

	static func dynamicCardBackground(_ colorScheme: ColorScheme) -> Color {
		return ThemeService.shared.cardBackgroundColor(for: colorScheme)
	}

	static func dynamicBorder(_ colorScheme: ColorScheme) -> Color {
		return ThemeService.shared.borderColor(for: colorScheme)
	}

	static func dynamicPlaceholderText(_ colorScheme: ColorScheme) -> Color {
		return ThemeService.shared.placeholderTextColor(for: colorScheme)
	}
}

//
//  Constants.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

let universalRectangleCornerRadius: CGFloat = 20
let universalNewRectangleCornerRadius: CGFloat = 8

// activity colors
let activityRedHexCode: String = "#FD4E4C"
let activityYellowHexCode: String = "#FBCD29"
let activityIndigoHexCode: String = "#536AEE"
let activityGreenHexCode: String = "#1AB979"
let activityPinkHexCode: String = "#ED64A6"
let activityTealHexCode: String = "#38B2AC"
let activityBlueHexCode: String = "#1E86E8"
let activityPurpleHexCode: String = "#713DE5"
let activityIndigoDarkHexCode: String = "#242CBB"

let activityColorHexCodes: [String] = [
	activityRedHexCode, activityYellowHexCode, activityIndigoHexCode,
	activityGreenHexCode, activityPinkHexCode, activityTealHexCode,
	activityBlueHexCode, activityPurpleHexCode, activityIndigoDarkHexCode
]
let activityColors = activityColorHexCodes.map { colorHexCode in
	Color(hex: colorHexCode)
}

// Function to deterministically assign colors to activities based on their ID
func getActivityColor(for activityId: UUID) -> Color {
	// Convert UUID to a consistent integer for indexing
	let uuidString = activityId.uuidString
	let hash = uuidString.hashValue
	let index = abs(hash) % activityColors.count
	print(index)
	return activityColors[index]
}

// Function to get the hex code for an activity color
func getActivityColorHex(for activityId: UUID) -> String {
	let uuidString = activityId.uuidString
	let hash = uuidString.hashValue
	let index = abs(hash) % activityColorHexCodes.count
	return activityColorHexCodes[index]
}

// MARK: - Dynamic Colors (Theme-aware)
// These are reactive functions that need to be called within an ObservedObject context

func universalBackgroundColor(from themeService: ThemeService, environment: ColorScheme) -> Color {
    let currentScheme = themeService.colorScheme
    
    switch currentScheme {
    case .light:
        return Color(hex: "#FFFFFF")
    case .dark:
        return Color(hex: "#000000")
    case .system:
        return environment == .dark ? Color(hex: "#000000") : Color(hex: "#FFFFFF")
    }
}

func universalAccentColor(from themeService: ThemeService, environment: ColorScheme) -> Color {
    let currentScheme = themeService.colorScheme
    
    switch currentScheme {
    case .light:
        return Color(hex: "#1D1D1D")
    case .dark:
        return Color(hex: "#FFFFFF")
    case .system:
        return environment == .dark ? Color(hex: "#FFFFFF") : Color(hex: "#1D1D1D")
    }
}

func universalPlaceHolderTextColor(from themeService: ThemeService, environment: ColorScheme) -> Color {
    let currentScheme = themeService.colorScheme
    
    switch currentScheme {
    case .light:
        return Color(hex: "#B0AFAF")
    case .dark:
        return Color(hex: "#6B6B6B")
    case .system:
        return environment == .dark ? Color(hex: "#6B6B6B") : Color(hex: "#B0AFAF")
    }
}

// Legacy computed properties for backwards compatibility (will use system theme only)
@available(iOS 14.0, *)
var universalBackgroundColor: Color {
    Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(Color(hex: "#000000"))
        default:
            return UIColor(Color(hex: "#FFFFFF"))
        }
    })
}

@available(iOS 14.0, *)
var universalAccentColor: Color {
    Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(Color(hex: "#FFFFFF"))
        default:
            return UIColor(Color(hex: "#1D1D1D"))
        }
    })
}

@available(iOS 14.0, *)
var universalPlaceHolderTextColor: Color {
    Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(Color(hex: "#6B6B6B"))
        default:
            return UIColor(Color(hex: "#B0AFAF"))
        }
    })
}

// MARK: - Static Colors (Theme-independent)
let universalSecondaryColorHexCode: String = "#8693FF"
let universalSecondaryColor: Color = Color(
    hex: universalSecondaryColorHexCode
)
let universalTertiaryColor: Color = Color(red: 1, green: 0.45, blue: 0.44)
let universalAccentColorHexCode: String = "#1D1D1D"
let universalPassiveColorHex: String = "#DADADA"
let universalPassiveColor: Color = Color(hex: universalPassiveColorHex)
let profilePicPlusButtonColor: Color = Color(hex: "#8693FF")
let authPageBackgroundColor: Color = Color(hex: "#8693FF")

// Colors from the Figma design
let figmaBlueHex: String = "#5667FF"
let figmaBlue: Color = Color(hex: figmaBlueHex)

let figmaSoftBlueHex: String = "#6B81FB"
let figmaSoftBlue: Color = Color(hex: figmaSoftBlueHex)

let figmaBlack300Hex: String = "#8E8484"
let figmaBlack300: Color = Color(hex: figmaBlack300Hex)

let figmaGreen: Color = Color(hex: "30D996")

let figmaBlack400Hex: String = "666060"
let figmaBlack400: Color = Color(hex: figmaBlack400Hex)

let figmaOrangeHex: String = "FF7270"
let figmaBittersweetOrange: Color = Color(hex: figmaOrangeHex)

let figmaGreyHex: String = "#F6F6F6"
let figmaGrey: Color = Color(hex: figmaGreyHex)

let figmaLightGreyHex: String = "#F2F2F2"
let figmaLightGrey: Color = Color(hex: figmaLightGreyHex)

let figmaGreyGradientColors: [Color] = [Color(hex: "#F0F0F0"), Color(hex: "#F1F1F1"), Color(hex: "#F2F2F2"), Color(hex: "#F3F3F3"), Color(hex: "#F4F4F4"), Color(hex: "#F5F5F5")]

let figmaTransparentWhite: Color = Color.white.opacity(0.8)

let figmaIndigoHex: String = "#536AEE"
let figmaIndigo: Color = Color(hex: figmaIndigoHex)

let figmaAuthButtonGreyHex: String = "#F5F5F5"
let figmaAuthButtonGrey: Color = Color(hex: figmaAuthButtonGreyHex)

// Default map location (UBC)
let defaultMapLatitude: Double = 49.26468617023799
let defaultMapLongitude: Double = -123.25859833051356

// Figma Typography
let heading1: Font = .onestSemiBold(size: 32)
let heading2: Font = .onestSemiBold(size: 28)
let body1: Font = .onestRegular(size: 20)

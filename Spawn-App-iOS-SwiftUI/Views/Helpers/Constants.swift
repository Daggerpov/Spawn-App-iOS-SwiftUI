//
//  Constants.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

let universalRectangleCornerRadius: CGFloat = 20
let universalNewRectangleCornerRadius: CGFloat = 8
let activityColorHexCodes: [String] = ["#00A676", "#FF7620", "#06AED5", "#FE5E6E"]
let activityColors = activityColorHexCodes.map { colorHexCode in
	Color(hex: colorHexCode)
}
let universalBackgroundColor: Color = Color(hex: "#FFFFFF")
let universalSecondaryColorHexCode: String = "#8693FF"
let universalSecondaryColor: Color = Color(
    hex: universalSecondaryColorHexCode
)
let universalTertiaryColor: Color = Color(red: 1, green: 0.45, blue: 0.44)
let universalAccentColorHexCode: String = "#1D1D1D"
let universalAccentColor: Color = Color(
	hex: universalAccentColorHexCode
)
let universalPassiveColorHex: String = "#DADADA"
let universalPassiveColor: Color = Color(hex: universalPassiveColorHex)
let profilePicPlusButtonColor: Color = Color(hex: "#8693FF")
let universalPlaceHolderTextColor: Color = Color(hex: "#B0AFAF")
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

// Default map location (UBC)
let defaultMapLatitude: Double = 49.26468617023799
let defaultMapLongitude: Double = -123.25859833051356

// Figma Typography
let heading1: Font = .onestSemiBold(size: 32)
let heading2: Font = .onestSemiBold(size: 28)
let body1: Font = .onestRegular(size: 20)

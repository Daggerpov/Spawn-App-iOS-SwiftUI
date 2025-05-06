//
//  Constants.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

let universalRectangleCornerRadius: CGFloat = 20
let universalNewRectangleCornerRadius: CGFloat = 8
let eventColorHexCodes: [String] = ["#00A676", "#FF7620", "#06AED5", "#FE5E6E"]
let eventColors = eventColorHexCodes.map { colorHexCode in
	Color(hex: colorHexCode)
}
let universalBackgroundColor: Color = Color(hex: "#FFFFFF")
let universalSecondaryColorHexCode: String = "#8693FF"
let universalSecondaryColor: Color = Color(
    hex: universalSecondaryColorHexCode
)
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

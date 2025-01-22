//
//  Constants.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

let universalRectangleCornerRadius: CGFloat = 20
let eventColorHexCodes: [String] = ["#9AA5D3", "#8FC9EE", "#A2C587", "#E2B06A"]
let eventColors = eventColorHexCodes.map { colorHexCode in
    Color(hex: colorHexCode)
}
let universalBackgroundColor: Color = Color(hex: "#E7E7DD")
let universalAccentColorHexCode: String = "#1D3D3D"
let universalAccentColor: Color = Color(
    hex: universalAccentColorHexCode
)
let profilPicPlusButtonColor: Color = Color(hex: "#D5583C")
let universalPlaceHolderTextColor: Color = Color(hex: "#B0AFAF")

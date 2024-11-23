//
//  Constants.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

let universalRectangleCornerRadius: CGFloat = 20
let eventColorHexCodes: [String] = ["#8084ac", "#704444", "#b0442c", "#889c6c"]
let eventColors = eventColorHexCodes.map { colorHexCode in
    Color(hex: colorHexCode)
}
let universalBackgroundColor: Color = Color(hex: "#E7E7DD")
let universalAccentColor: Color = Color(hex: "#1D3D3D") // TODO: might want to define this in assets folder instead
let profilPicPlusButtonColor: Color = Color(hex: "#D5583C")
let addButtonColor: Color = Color(hex: "#E7E7DD")
let universalPlaceHolderTextColor: Color = Color(hex: "#B0AFAF")


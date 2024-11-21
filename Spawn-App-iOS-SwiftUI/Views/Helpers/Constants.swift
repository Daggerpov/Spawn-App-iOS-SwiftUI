//
//  Constants.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

let universalRectangleCornerRadius: CGFloat = 20
let eventColorHexCodes: [String] = ["#8084ac", "#8084ac", "#8084ac", "#8084ac"]
let eventColors = eventColorHexCodes.map { colorHexCode in
    Color(hex: colorHexCode)
}
let universalBackgroundColor: Color = Color(hex: "#E7E7DD")
let universalAccentColor: Color = Color(hex: "#203434") // TODO: might want to define this in assets folder instead

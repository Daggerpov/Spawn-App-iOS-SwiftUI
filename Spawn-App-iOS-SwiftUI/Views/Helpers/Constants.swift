//
//  Constants.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

// MARK: - Dimensions and Spacing
let dimensionScale: CGFloat = 2
let dimensionXS: CGFloat = 4
let dimensionSM: CGFloat = 8
let dimensionMD: CGFloat = 16
let dimensionLG: CGFloat = 32
let dimensionXL: CGFloat = 64

let spacingXS: CGFloat = dimensionXS
let spacingSM: CGFloat = dimensionSM
let spacingMD: CGFloat = dimensionMD
let spacingLG: CGFloat = dimensionLG
let spacingXL: CGFloat = dimensionXL

// MARK: - Border Radius
let borderRadiusSM: CGFloat = 4
let borderRadiusMD: CGFloat = 8
let borderRadiusLG: CGFloat = 12
let borderRadiusXL: CGFloat = 16
let borderRadiusFull: CGFloat = 100

// Legacy corner radius for backwards compatibility
let universalRectangleCornerRadius: CGFloat = 20
let universalNewRectangleCornerRadius: CGFloat = borderRadiusMD

// MARK: - Core Colors
let colorsBlack: String = "#000000"
let colorsWhite: String = "#FFFFFF"

// MARK: - Gray Colors
let colorsGray50: String = "#F2EEEE"
let colorsGray100: String = "#E0DADA"
let colorsGray200: String = "#D1CBCB"
let colorsGray300: String = "#A9A0A0"
let colorsGray400: String = "#857C7C"
let colorsGray500: String = "#625A5A"
let colorsGray600: String = "#3E3B3B"
let colorsGray700: String = "#262424"
let colorsGray800: String = "#1F1E1E"
let colorsGray900: String = "#1A1A1A"
let colorsGrayInput: String = "#F5F5F5"

// MARK: - Indigo Colors
let colorsIndigo100: String = "#EBEEFD"
let colorsIndigo200: String = "#DADFFF"
let colorsIndigo300: String = "#B6C1FF"
let colorsIndigo400: String = "#91A2FF"
let colorsIndigo500: String = "#6B81FB"
let colorsIndigo600: String = "#536AEE"
let colorsIndigo700: String = "#344DDE"
let colorsIndigo800: String = "#242CBB"
let colorsIndigo900: String = "#1B1D9E"

// MARK: - Red Colors
let colorsRed100: String = "#FFF5F5"
let colorsRed200: String = "#FED7D7"
let colorsRed300: String = "#FEB2B2"
let colorsRed400: String = "#FB8987"
let colorsRed500: String = "#FF7270"
let colorsRed600: String = "#FD4E4C"
let colorsRed700: String = "#C53030"
let colorsRed800: String = "#9B2C2C"
let colorsRed900: String = "#901919"

// MARK: - Yellow Colors
let colorsYellow100: String = "#FFFFF0"
let colorsYellow200: String = "#FEFCBF"
let colorsYellow300: String = "#FFF482"
let colorsYellow400: String = "#FEE345"
let colorsYellow500: String = "#FACC28"
let colorsYellow600: String = "#D69E2E"
let colorsYellow700: String = "#B7791F"
let colorsYellow800: String = "#975A16"
let colorsYellow900: String = "#744210"

// MARK: - Green Colors
let colorsGreen100: String = "#E7FFF5"
let colorsGreen200: String = "#A4F7D6"
let colorsGreen300: String = "#78F6C3"
let colorsGreen400: String = "#46DEA1"
let colorsGreen500: String = "#30D895"
let colorsGreen600: String = "#1AB979"
let colorsGreen700: String = "#098151"
let colorsGreen800: String = "#045D39"
let colorsGreen900: String = "#045D39"

// MARK: - Teal Colors
let colorsTeal100: String = "#E6FFFA"
let colorsTeal200: String = "#B2F5EA"
let colorsTeal300: String = "#81E6D9"
let colorsTeal400: String = "#4FD1C5"
let colorsTeal500: String = "#38B2AC"
let colorsTeal600: String = "#319795"
let colorsTeal700: String = "#2C7A7B"
let colorsTeal800: String = "#285E61"
let colorsTeal900: String = "#234E52"

// MARK: - Blue Colors
let colorsBlue100: String = "#EBF8FF"
let colorsBlue200: String = "#B4E4FF"
let colorsBlue300: String = "#85CFFF"
let colorsBlue400: String = "#5CBAFF"
let colorsBlue500: String = "#34A2FD"
let colorsBlue600: String = "#1D85E7"
let colorsBlue700: String = "#0B6ACD"
let colorsBlue800: String = "#0D51A6"
let colorsBlue900: String = "#0D438B"

// MARK: - Purple Colors
let colorsPurple100: String = "#EAD5FF"
let colorsPurple200: String = "#D1ACFD"
let colorsPurple300: String = "#BF92FF"
let colorsPurple400: String = "#A775FF"
let colorsPurple500: String = "#8A53FB"
let colorsPurple600: String = "#703CE5"
let colorsPurple700: String = "#6939D9"
let colorsPurple800: String = "#5430B5"
let colorsPurple900: String = "#341A83"

// MARK: - Pink Colors
let colorsPink100: String = "#FFF5F7"
let colorsPink200: String = "#FED7E2"
let colorsPink300: String = "#FBB6CE"
let colorsPink400: String = "#F687B3"
let colorsPink500: String = "#ED64A6"
let colorsPink600: String = "#D53F8C"
let colorsPink700: String = "#B83280"
let colorsPink800: String = "#97266D"
let colorsPink900: String = "#702459"

// MARK: - Dark Brand Colors
let colorsTabIconActive: String = "#536AEE"
let colorsTabIconInactive: String = "#4B527F"
let colorsTabBackground: String = "#DFE2F5"

// MARK: - Transparent Colors
let colorsTransparentBlack0: String = "#00000000"
let colorsTransparentBlack20: String = "#00000033"
let colorsTransparentBlack40: String = "#00000066"
let colorsTransparentBlack60: String = "#00000099"
let colorsTransparentBlack80: String = "#000000CC"

let colorsTransparentGray20: String = "#13121233"
let colorsTransparentGray40: String = "#13121266"
let colorsTransparentGray60: String = "#13121299"
let colorsTransparentGray80: String = "#131212CC"

let colorsTransparentWhite0: String = "#FFFFFF00"
let colorsTransparentWhite20: String = "#FFFFFF33"
let colorsTransparentWhite40: String = "#FFFFFF66"
let colorsTransparentWhite60: String = "#FFFFFF99"
let colorsTransparentWhite80: String = "#FFFFFFCC"

// MARK: - Opacity Values
let opacity10: CGFloat = 0.10
let opacity25: CGFloat = 0.25
let opacity40: CGFloat = 0.40
let opacity50: CGFloat = 0.50
let opacity60: CGFloat = 0.60
let opacity75: CGFloat = 0.75
let opacity90: CGFloat = 0.90

// MARK: - Activity Colors (using new design system)
let activityRedHexCode: String = colorsRed600
let activityOrangeHexCode: String = "#FF6B35" // Custom orange not in design system
let activityIndigoHexCode: String = colorsIndigo600
let activityGreenHexCode: String = colorsGreen600
let activityPinkHexCode: String = colorsPink500
let activityTealHexCode: String = colorsTeal500
let activityBlueHexCode: String = colorsBlue600
let activityPurpleHexCode: String = colorsPurple600
let activityIndigoDarkHexCode: String = colorsIndigo800

let activityColorHexCodes: [String] = [
	activityRedHexCode, activityOrangeHexCode, activityIndigoHexCode,
	activityGreenHexCode, activityPinkHexCode, activityTealHexCode,
	activityBlueHexCode, activityPurpleHexCode, activityIndigoDarkHexCode
]
let activityColors = activityColorHexCodes.map { colorHexCode in
	Color(hex: colorHexCode)
}

// Function to get evenly distributed colors for activities with caching
func getActivityColor(for activityId: UUID) -> Color {
	return ActivityColorService.shared.getColorForActivity(activityId)
}

// Function to get the hex code for an activity color
func getActivityColorHex(for activityId: UUID) -> String {
	return ActivityColorService.shared.getColorHexForActivity(activityId)
}

// MARK: - Dynamic Colors (Theme-aware)
// These are reactive functions that need to be called within an ObservedObject context

func universalBackgroundColor(from themeService: ThemeService, environment: ColorScheme) -> Color {
    let currentScheme = themeService.colorScheme
    
    switch currentScheme {
    case .light:
        return Color(hex: colorsWhite)
    case .dark:
        return Color(hex: colorsGray900)
    case .system:
        return environment == .dark ? Color(hex: colorsGray900) : Color(hex: colorsWhite)
    }
}

func universalAccentColor(from themeService: ThemeService, environment: ColorScheme) -> Color {
    let currentScheme = themeService.colorScheme
    
    switch currentScheme {
    case .light:
        return Color(hex: colorsGray900)
    case .dark:
        return Color(hex: colorsWhite)
    case .system:
        return environment == .dark ? Color(hex: colorsWhite) : Color(hex: colorsGray900)
    }
}

func universalPlaceHolderTextColor(from themeService: ThemeService, environment: ColorScheme) -> Color {
    let currentScheme = themeService.colorScheme
    
    switch currentScheme {
    case .light:
        return Color(hex: colorsGray400)
    case .dark:
        return Color(hex: colorsGray500)
    case .system:
        return environment == .dark ? Color(hex: colorsGray500) : Color(hex: colorsGray400)
    }
}

// Legacy computed properties for backwards compatibility (will use system theme only)
@available(iOS 14.0, *)
var universalBackgroundColor: Color {
    Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(Color(hex: colorsGray900))
        default:
            return UIColor(Color(hex: colorsWhite))
        }
    })
}

@available(iOS 14.0, *)
var universalAccentColor: Color {
    Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(Color(hex: colorsWhite))
        default:
            return UIColor(Color(hex: colorsGray900))
        }
    })
}

@available(iOS 14.0, *)
var universalPlaceHolderTextColor: Color {
    Color(UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(Color(hex: colorsGray500))
        default:
            return UIColor(Color(hex: colorsGray400))
        }
    })
}

// MARK: - Static Colors (Theme-independent) - Updated to use new design system
let universalSecondaryColorHexCode: String = colorsIndigo400
let universalSecondaryColor: Color = Color(hex: universalSecondaryColorHexCode)
let universalTertiaryColor: Color = Color(hex: colorsRed500)
let universalAccentColorHexCode: String = colorsGray900
let universalPassiveColorHex: String = colorsGray200
let universalPassiveColor: Color = Color(hex: universalPassiveColorHex)
let profilePicPlusButtonColor: Color = Color(hex: colorsIndigo400)
let authPageBackgroundColor: Color = Color(hex: colorsIndigo400)

// Colors from the Figma design (updated to use new design system)

let figmaBlueHex: String = colorsBlue700
let figmaBlue: Color = Color(hex: figmaBlueHex)

let figmaSoftBlueHex: String = colorsIndigo500
let figmaSoftBlue: Color = Color(hex: figmaSoftBlueHex)

let figmaBlack300Hex: String = colorsGray400
let figmaBlack300: Color = Color(hex: figmaBlack300Hex)

let figmaGreen: Color = Color(hex: colorsGreen500)

let figmaBlack400Hex: String = colorsGray500
let figmaBlack400: Color = Color(hex: figmaBlack400Hex)

let figmaOrangeHex: String = colorsRed500
let figmaBittersweetOrange: Color = Color(hex: figmaOrangeHex)

let figmaGreyHex: String = colorsGray50
let figmaGrey: Color = Color(hex: figmaGreyHex)

let figmaLightGreyHex: String = colorsGray100
let figmaLightGrey: Color = Color(hex: figmaLightGreyHex)

let figmaCalendarDayIconHex: String = colorsGray200
let figmaCalendarDayIcon: Color = Color(hex: figmaCalendarDayIconHex)

let figmaGreyGradientColors: [Color] = [
    Color(hex: colorsGray50), Color(hex: colorsGray100), Color(hex: colorsGray200), 
    Color(hex: colorsGray300), Color(hex: colorsGray400), Color(hex: colorsGray500)
]

let figmaTransparentWhite: Color = Color(hex: colorsTransparentWhite80)

let figmaIndigoHex: String = colorsIndigo600
let figmaIndigo: Color = Color(hex: figmaIndigoHex)

let figmaAuthButtonGreyHex: String = colorsGray100
let figmaAuthButtonGrey: Color = Color(hex: figmaAuthButtonGreyHex)

// Default map location (UBC)
let defaultMapLatitude: Double = 49.26468617023799
let defaultMapLongitude: Double = -123.25859833051356

// Figma Typography
let heading1: Font = .onestSemiBold(size: 32)
let heading2: Font = .onestSemiBold(size: 28)
let body1: Font = .onestRegular(size: 20)

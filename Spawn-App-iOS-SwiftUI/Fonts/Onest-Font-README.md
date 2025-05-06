# Fonts for Spawn App

This directory contains font files used in the Spawn App.

## Onest Font

The Onest font family is used throughout the app, with the following weights:

- **Onest-Regular.ttf** - Used for regular text
- **Onest-Medium.ttf** - Used for slightly emphasized text
- **Onest-Bold.ttf** - Used for headings and strong emphasis

## Usage

The font is registered and applied globally in the `Spawn_App_iOS_SwiftUIApp.swift` file. 

Font extensions and modifiers are available to easily apply the font:

```swift
// Apply Onest font directly
Text("Hello")
    .font(.onestRegular(size: 16))

// Use convenience extension methods
Text("Hello")
    .onestFont(size: 16, weight: .medium)

// Use predefined text styles
Text("Hello")
    .onestHeadline()
    .onestSubheadline()
    .onestBody()
    .onestCaption()
    .onestSmallText()
```

## License

The Onest font is licensed under the SIL Open Font License (OFL). 
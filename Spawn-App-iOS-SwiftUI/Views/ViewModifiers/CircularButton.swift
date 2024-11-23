//
//  CircularButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

extension Circle {
    func CircularButton (systemName: String, buttonActionCallback: @escaping() -> Void, width: CGFloat? = 17.5, height: CGFloat? = 17.5, frameSize: CGFloat? = 40, source: String? = "default") -> some View {
        return self
            .frame(width: frameSize, height: frameSize)
            .foregroundColor(
                source == "map" ? universalBackgroundColor : Color.white
            )
            .background(source == "map" ? universalBackgroundColor : Color.white)
            .clipShape(Circle())
            .overlay(
                Group{
                    if source == "map" {
                        Circle()
                            .stroke(universalAccentColor, lineWidth: 2)
                    } else {
                        EmptyView()
                    }
                }
            )
            .overlay(
                Button(action: {
                    buttonActionCallback()
                }) {
                    Image(systemName: systemName)
                        .resizable()
                        .frame(width: width, height: height)
                        .shadow(radius: 20)
                        .foregroundColor(universalAccentColor)
                }
            )
    }
}

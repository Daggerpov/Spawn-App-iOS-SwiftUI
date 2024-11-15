//
//  CircularButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

extension Circle {
    func CircularButton (systemName: String, buttonActionCallback: @escaping() -> Void, width: CGFloat? = 17.5, height: CGFloat? = 17.5, frameSize: CGFloat? = 40) -> some View {
        return self
            .frame(width: frameSize, height: frameSize)
            .foregroundColor(Color.white)
            .background(Color.white)
            .clipShape(Circle())
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

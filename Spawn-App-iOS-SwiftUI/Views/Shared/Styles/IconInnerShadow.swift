//
//  IconInnerShadow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Ethan Hansen on 2025-08-21.
//


import SwiftUI

struct IconInnerShadow: ViewModifier {
    var color: Color
    var radius: CGFloat
    var x: CGFloat = 0
    var y: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: radius)
                    .shadow(color: color.opacity(0.3), radius: radius, x: x, y: y)
                    .clipShape(Circle())
            )
            .mask(
                Circle()
            )
    }
}


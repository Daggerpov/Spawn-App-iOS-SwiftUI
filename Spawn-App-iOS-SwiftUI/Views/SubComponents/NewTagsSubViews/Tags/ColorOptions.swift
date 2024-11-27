//
//  ColorOptions.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct ColorOptions: View {
    @State var currentSelectedColorIndex: Int = 0
    var body: some View {
        HStack(spacing: 15) {
            // Iterate through eventColors and add a plus circle at the end
            ForEach(0..<eventColors.count, id: \.self) { index in
                Button(action: {
                    currentSelectedColorIndex = index
                }) {
                    Circle()
                        .stroke(index == currentSelectedColorIndex ? universalAccentColor : Color.white, lineWidth: 2)
                        .fill(eventColors[index])
                        .frame(width: 35, height: 35)
                }
            }
            
            Circle()
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [5, 3] // Length of dash and gap
                    )
                )
                .fill(Color.gray.opacity(0.2))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "plus").foregroundColor(.white)
                )
            Spacer()
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 3)
    }
}

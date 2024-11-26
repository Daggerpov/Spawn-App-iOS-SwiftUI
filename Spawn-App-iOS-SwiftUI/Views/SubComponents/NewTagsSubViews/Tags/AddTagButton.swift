//
//  AddTagButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct AddTagButton: View {
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(universalAccentColor, style: StrokeStyle(lineWidth: 2, dash: [4]))
                .frame(height: 50)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(universalAccentColor)
                )
        }
    }
}

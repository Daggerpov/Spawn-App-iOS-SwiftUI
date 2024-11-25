//
//  TagRow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagRow: View {
    var friendTag: FriendTag
    @State private var isExpanded: Bool = false

    var body: some View {
        HStack {
            Text(friendTag.displayName)
                .foregroundColor(.white)
                .font(.subheadline)
            Spacer()
            HStack(spacing: -10) {
                ForEach(0..<2) { _ in
                    Circle()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray.opacity(0.2))
                }
                Button(action: {
                    withAnimation {
                        isExpanded.toggle() // Toggle expanded state
                        
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(universalAccentColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                .fill(Color(hex: friendTag.colorHexCode))
        )
        if isExpanded {
            ExpandedTagView(friendTag: friendTag)
        }
    }
}

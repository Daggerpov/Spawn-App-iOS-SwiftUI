//
//  TagRow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagRow: View {
    @EnvironmentObject var user: ObservableUser
    var tagName: String
    var color: Color
    var action: () -> Void = {}
    
    var body: some View {
        HStack {
            Text(tagName)
                .font(.subheadline)
            Spacer()
            HStack(spacing: -10) {
                ForEach(0..<2) { _ in
                    Circle()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray.opacity(0.2))
                }
                Button(action: action) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                .fill(color)
        )
    }
}

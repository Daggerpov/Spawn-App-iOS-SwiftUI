//
//  SearchBarButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 5/18/25.
//

import SwiftUI

struct SearchBarButtonView: View {
    var placeholder: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.onestRegular(size: 18))
                    .foregroundColor(.gray)
                
                Text(placeholder)
                    .font(.onestRegular(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: universalRectangleCornerRadius
                        )
                            .inset(by: 0.75)
                            .stroke(.gray)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchBarButtonView(placeholder: "Search for friends", action: {})
        .padding()
        .previewLayout(.sizeThatFits)
} 
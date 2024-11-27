//
//  ExpandedTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct ExpandedTagView: View {
    var friendTag: FriendTag
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Spacer()
            }

            ColorOptions()
            FriendContainer(friendTag: friendTag)
        }
        .padding()
        .padding(.bottom)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: friendTag.colorHexCode).opacity(0.2))
        )
    }
}

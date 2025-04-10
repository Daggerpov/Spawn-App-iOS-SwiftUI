//
//  AddFriendsToTagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 3/28/25.
//

import SwiftUI

struct AddFriendsToTagButtonView: View {
    var addFriendsToTagButtonPressedCallback: ((UUID) -> Void)? = { thing in }

    var friendTagId: UUID?
    
    var body: some View {
        VStack {
            Button(action: {
                if let tagId = friendTagId,
                   let callback = addFriendsToTagButtonPressedCallback
                {
                    callback(tagId)
                }
            }) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        .white, style: StrokeStyle(lineWidth: 2, dash: [4])
                    )
                    .frame(height: 50)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .padding(.bottom, 10)
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    AddFriendsToTagButtonView()
}

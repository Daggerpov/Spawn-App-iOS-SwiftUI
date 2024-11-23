//
//  TagsScrollView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct TagsScrollView: View {
    var tags: [FriendTag]
    @State private var activeTag: String = "Everyone"
    @Namespace private var animation: Namespace.ID
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tags, id: \.self) { mockTag in
                    TagButtonView(mockTag: mockTag.displayName, activeTag: $activeTag, animation: animation)
                }
            }
            .padding(.top, 10)
            .padding(.leading, 16)
            .padding(.trailing, 16)
        }
    }
    
}

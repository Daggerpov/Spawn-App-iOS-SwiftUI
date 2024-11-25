//
//  TagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagsTabView: View {
    let user: User
    
    var body: some View {
        VStack{
            tagSection
            Spacer()
            Spacer()
            Spacer()
            otherTagsSection
        }
        .padding()
    }
}

extension TagsTabView {
    var tagSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("TAGS")
                .font(.headline)
            
            AddTagButton()
        }
    }
    
    var otherTagsSection: some View {
        Group {
            if let tags = user.friendTags, !tags.isEmpty {
                VStack(spacing: 15) {
                    ForEach(tags) { friendTag in
                        TagRow(friendTag: friendTag)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: friendTag.colorHexCode).opacity(0.2)))
                    }
                }
            }
        }
    }
}

//
//  TagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct TagButtonView: View {
    let mockTag: String
    @Binding var activeTag: String
    var animation: Namespace.ID
    
    var body: some View {
        Button(action: {
            withAnimation(.easeIn) {
                activeTag = mockTag
            }
        }) {
            Text(mockTag)
                .font(.callout)
                .foregroundColor(activeTag == mockTag ? .white : Color(hex: "#173131"))
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background{
                    Capsule()
                        .fill(activeTag == mockTag ? Color(hex: "#173131") : .white)
                        .matchedGeometryEffect(id: "ACTIVETAG_\(mockTag)", in: animation) // Use unique ID for each tag
                }
                
        }
        .buttonStyle(.plain)
    }
}

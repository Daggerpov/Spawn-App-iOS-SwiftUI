//
//  ProfileImages.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

extension Image {
    func ProfileImageModifier(imageType: ProfileImageType) -> some View {
        let imageSize: CGFloat
        let strokeColor: Color
        let lineWidth: CGFloat
        
        switch imageType {
            case .feedPage:
                imageSize = 55
                strokeColor = .black
                lineWidth = 2
            case .friendsListView:
                imageSize = 50
                strokeColor = .black
                lineWidth = 0
            case .eventParticipants, .chatMessage:
                imageSize = 25
                strokeColor = .white
                lineWidth = 1
            case .profilePage:
                imageSize = 150
                strokeColor = .black
                lineWidth = 0
        }
        
        return self
            .resizable()
            .frame(width: imageSize, height: imageSize)
            .clipShape(Circle())
            .overlay(Circle().stroke(strokeColor, lineWidth: lineWidth))
            .shadow(radius: 10)
    }
}

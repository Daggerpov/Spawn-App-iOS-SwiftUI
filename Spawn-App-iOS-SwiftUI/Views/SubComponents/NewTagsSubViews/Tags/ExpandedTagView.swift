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

			// TODO: change this later to be a properly shared hex code statep 
			ColorOptions(
				currentSelectedColorHexCode:
						.constant(universalAccentColorHexCode)
			)
            FriendContainer(friendTag: friendTag)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

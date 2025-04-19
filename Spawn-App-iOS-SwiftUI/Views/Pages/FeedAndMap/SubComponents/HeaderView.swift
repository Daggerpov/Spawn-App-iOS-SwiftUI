//
//  HeaderView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct HeaderView: View {
	var user: BaseUserDTO
	var body: some View {
		HStack {
			Spacer()
			VStack {
				HStack {
					Text("Hello,")
						.font(.title)
					Spacer()
				}

				HStack {
					Image(systemName: "star.fill")
					Text(user.username)
						.bold()
					Spacer()
				}
				.font(.title)
			}
			.foregroundColor(universalAccentColor)
			.frame(alignment: .leading)
			Spacer()

			if let profilePictureString = user.profilePicture {
				NavigationLink {
					ProfileView(user: user)
				} label: {
					if MockAPIService.isMocking {
						Image(profilePictureString)
							.ProfileImageModifier(imageType: .feedPage)
					} else {
						AsyncImage(url: URL(string: profilePictureString)) {
							image in
							image
								.ProfileImageModifier(imageType: .feedPage)
						} placeholder: {
							Circle()
								.fill(Color.gray)
								.frame(width: 55, height: 55)  // 55 matches .feedPage image type for `ProfileImageModifier`
						}
					}
				}
			}
			Spacer()
		}
		.padding(.horizontal)
		.padding(.vertical, 2)
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	HeaderView(user: BaseUserDTO.danielAgapov)
}


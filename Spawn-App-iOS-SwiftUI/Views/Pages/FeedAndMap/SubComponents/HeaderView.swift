//
//  HeaderView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct HeaderView: View {
	var user: BaseUserDTO
	//var numActivities: Int
	var body: some View {
		HStack {
			Spacer()
			VStack {
				HStack {
					Text(
						"Hey \(user.name?.components(separatedBy: " ").first ?? user.username)! 👋"
					)
					.font(.onestBold(size: 32))
					.foregroundColor(universalAccentColor)
					Spacer()
				}
				.font(.onestBold(size: 32))
				Spacer().frame(height: 5)
			}
			.frame(alignment: .leading)
			Spacer()
			Spacer()
		}
		.padding(.vertical, 2)
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @StateObject var appCache = AppCache.shared
	HeaderView(user: BaseUserDTO.danielAgapov).environmentObject(
		appCache
	)
}

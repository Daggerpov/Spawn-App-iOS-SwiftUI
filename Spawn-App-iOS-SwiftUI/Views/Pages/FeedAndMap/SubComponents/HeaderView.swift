//
//  HeaderView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct HeaderView: View {
	var user: BaseUserDTO
    var numEvents: Int
	var body: some View {
		HStack {
			Spacer()
			VStack {
                Image("SpawnLogo")
                Spacer().frame(height: 61)
				HStack {
                    Text("Hey \(user.firstName ?? user.username)! 👋")
					Spacer()
				}
                .font(.onestBold(size: 32))
                Spacer().frame(height: 5)
                HStack {
                    Text("There are ").font(.onestRegular(size: 16))
                    + Text("\(numEvents) events ").foregroundColor(figmaSoftBlue).font(.onestBold(size: 16))
                    + Text("in your area.").font(.onestRegular(size: 16))
                    Spacer()
                }
			}
			.foregroundColor(universalAccentColor)
			.frame(alignment: .leading)
			Spacer()
			Spacer()
		}
		.padding(.horizontal)
		.padding(.vertical, 2)
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	HeaderView(user: BaseUserDTO.danielAgapov, numEvents: 2).environmentObject(appCache)
}


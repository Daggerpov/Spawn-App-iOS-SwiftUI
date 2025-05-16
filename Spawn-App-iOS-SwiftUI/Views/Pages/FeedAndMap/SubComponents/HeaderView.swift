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
                    Text("Hey \(user.name?.components(separatedBy: " ")[0] ?? user.username)! 👋")
					Spacer()
				}
                .font(.onestBold(size: 32))
                Spacer().frame(height: 5)
                eventsInAreaView
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

extension HeaderView {
    var eventsInAreaView: some View {
        HStack {
            Text("There are ").font(.onestSemiBold(size: 20))
            + Text("\(numEvents) events ").foregroundColor(figmaSoftBlue).font(.onestSemiBold(size: 20))
            + Text("in your area.").font(.onestSemiBold(size: 20))
            Spacer()
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	HeaderView(user: BaseUserDTO.danielAgapov, numEvents: 2).environmentObject(appCache)
}


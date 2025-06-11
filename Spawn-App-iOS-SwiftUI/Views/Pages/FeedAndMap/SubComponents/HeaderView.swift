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
				Image("SpawnLogo")
				Spacer().frame(height: 61)
				HStack {
					Text(
						"Hey \(user.name?.components(separatedBy: " ")[0] ?? user.username)! 👋"
					)
					Spacer()
				}
				.font(.onestBold(size: 32))
				Spacer().frame(height: 5)
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

//extension HeaderView {
//	var eventsInAreaView: some View {
//		HStack {
//			if numEvents == 0 {
//				Text("There is ").font(.onestSemiBold(size: 20))
//					+ Text("1 event ").foregroundColor(figmaSoftBlue).font(
//						.onestSemiBold(size: 20)
//					)
//					+ Text("in your area.").font(.onestSemiBold(size: 20))
//			} else {
//				Text("There are ").font(.onestSemiBold(size: 20))
//					+ Text("\(numEvents) events ").foregroundColor(
//						figmaSoftBlue
//					).font(.onestSemiBold(size: 20))
//					+ Text("in your area.").font(.onestSemiBold(size: 20))
//			}
//			Spacer()
//		}
//	}
//}

@available(iOS 17, *)
#Preview {
	@Previewable @StateObject var appCache = AppCache.shared
	HeaderView(user: BaseUserDTO.danielAgapov).environmentObject(
		appCache
	)
}

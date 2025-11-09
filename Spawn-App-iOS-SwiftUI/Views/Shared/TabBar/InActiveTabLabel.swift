import SwiftUI

struct InActiveTabLabel: View {
	let tabItem: TabItem

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: CORNER_RADIUS)
				.fill(.clear)
				.frame(width: 80, height: BTTN_HEIGHT)
			if #available(iOS 17.0, *) {
				VStack(spacing: 1) {
					Image(
						uiImage: resizeImage(
							UIImage(named: tabItem.inactiveIcon)!,
							targetSize: CGSize(width: ICON_SIZE, height: ICON_SIZE)
						)!)
					Text(tabItem.title)
						.font(.onestRegular(size: 12))
						.fontWeight(.medium)
				}
				.symbolEffectsRemoved()
			} else {
				// Fallback for iOS < 17 (without symbol effects)
				VStack(spacing: 1) {
					Image(
						uiImage: resizeImage(
							UIImage(named: tabItem.inactiveIcon)!,
							targetSize: CGSize(width: ICON_SIZE, height: ICON_SIZE)
						)!)
					Text(tabItem.title)
						.font(.onestRegular(size: 12))
						.fontWeight(.medium)
				}
			}
		}
	}
}

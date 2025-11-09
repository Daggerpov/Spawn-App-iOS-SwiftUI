import SwiftUI

struct SmallTextModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(.onestRegular(size: 12))
	}
}

import SwiftUI

struct BodyModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(.onestRegular(size: 16))
	}
}

import SwiftUI

struct SubheadlineModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(.onestMedium(size: 16))
	}
}

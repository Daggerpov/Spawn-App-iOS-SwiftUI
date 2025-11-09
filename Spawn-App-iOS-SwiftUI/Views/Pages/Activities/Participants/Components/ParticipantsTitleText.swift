import SwiftUI

// Shared title text component
struct ParticipantsTitleText: View {
	var body: some View {
		Text("Who's Coming?")
			.font(Font.custom("Onest", size: 20).weight(.semibold))
			.foregroundColor(.white)
	}
}

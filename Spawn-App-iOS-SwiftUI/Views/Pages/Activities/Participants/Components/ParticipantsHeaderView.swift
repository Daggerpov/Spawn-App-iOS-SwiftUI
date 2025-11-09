import SwiftUI

// Shared header view component
struct ParticipantsHeaderView: View {
	let onBack: () -> Void

	var body: some View {
		HStack {
			ParticipantsBackButton(action: onBack)
			Spacer()
			ParticipantsTitleText()
			Spacer()
			InvisibleBalanceButton()
		}
		.padding(.horizontal, 24)
		.padding(.bottom, 16)
	}
}

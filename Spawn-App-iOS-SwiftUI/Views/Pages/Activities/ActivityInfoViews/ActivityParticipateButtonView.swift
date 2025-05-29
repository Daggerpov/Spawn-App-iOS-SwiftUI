//
//  ActivityParticipateButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct ActivityParticipateButtonView: View {
	var toggleParticipationCallback: () -> Void
	var isParticipating: Bool
	var body: some View {
		Circle()
			.CircularButton(
				systemName: isParticipating ? "checkmark" : "star.fill",
				buttonActionCallback: {
					toggleParticipationCallback()
				})
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	ActivityParticipateButtonView(toggleParticipationCallback: {}, isParticipating: true).environmentObject(appCache)
}

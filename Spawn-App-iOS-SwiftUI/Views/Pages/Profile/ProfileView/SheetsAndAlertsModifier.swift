//
//  SheetsAndAlertsModifier.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//
import SwiftUI

struct SheetsAndAlertsModifier: ViewModifier {
	@Binding var showActivityDetails: Bool
	let activityDetailsView: AnyView
	@Binding var showRemoveFriendConfirmation: Bool
	let removeFriendConfirmationAlert: AnyView
	@Binding var showReportDialog: Bool
	let reportUserDrawer: AnyView
	@Binding var showBlockDialog: Bool
	let blockUserAlert: AnyView
	@Binding var showProfileMenu: Bool
	let profileMenuSheet: AnyView
	
	func body(content: Content) -> some View {
		content
			.overlay(
				// Use overlay instead of sheet for ActivityPopupDrawer consistency
				Group {
					if showActivityDetails {
						activityDetailsView
					}
				}
			)
			.alert("Remove Friend", isPresented: $showRemoveFriendConfirmation) {
				removeFriendConfirmationAlert
			}
			.sheet(isPresented: $showReportDialog) {
				reportUserDrawer
			}
			.alert("Block User", isPresented: $showBlockDialog) {
				blockUserAlert
			} message: {
				Text("Blocking this user will remove them from your friends list and they won't be able to see your profile or activities.")
			}
			.sheet(isPresented: $showProfileMenu) {
				profileMenuSheet
			}
	}
}


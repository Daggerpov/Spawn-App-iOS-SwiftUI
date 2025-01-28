//
//  UserAuthViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import SwiftUI
import GoogleSignIn
import UIKit

class UserAuthViewModel: ObservableObject {

	@Published var givenName: String = ""
	@Published var profilePicUrl: String = ""
	@Published var isLoggedIn: Bool = false
	@Published var errorMessage: String = ""

	init(){
		check()
	}

	func checkStatus(){
		if(GIDSignIn.sharedInstance.currentUser != nil){
			let user = GIDSignIn.sharedInstance.currentUser
			guard let user = user else { return }
			let givenName = user.profile?.givenName
			let profilePicUrl = user.profile!.imageURL(withDimension: 100)!.absoluteString
			self.givenName = givenName ?? ""
			self.profilePicUrl = profilePicUrl
			self.isLoggedIn = true
		}else{
			self.isLoggedIn = false
			self.givenName = "Not Logged In"
			self.profilePicUrl =  ""
		}
	}

	func check(){
		GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
			if let error = error {
				self.errorMessage = "error: \(error.localizedDescription)"
			}

			self.checkStatus()
		}
	}

	func signIn() {
		guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
			self.errorMessage = "Error: Unable to get the presenting view controller."
			return
		}

		GIDConfiguration(clientID: "822760465266-hl53d2rku66uk4cljschig9ld0ur57na.apps.googleusercontent.com")

		// Trigger the sign-in flow
		GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
			if let error = error {
				self.errorMessage = "Error: \(error.localizedDescription)"
				return
			}

			// Retrieve user info if sign-in is successful
			guard let user = signInResult?.user else { return }
			self.givenName = user.profile?.givenName ?? ""
			self.profilePicUrl = user.profile?.imageURL(withDimension: 100)?.absoluteString ?? ""
			self.isLoggedIn = true
		}
	}

	func signOut(){
		GIDSignIn.sharedInstance.signOut()
		self.checkStatus()
	}
}

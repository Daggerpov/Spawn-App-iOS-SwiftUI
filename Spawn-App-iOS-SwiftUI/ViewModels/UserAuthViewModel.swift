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
	static let shared: UserAuthViewModel = UserAuthViewModel(apiService: MockAPIService.isMocking ? MockAPIService() : APIService()) // Singleton instance
	@Published var errorMessage: String?

	@Published var givenName: String?
	@Published var fullName: String?
	@Published var familyName: String?
	@Published var email: String?
	@Published var profilePicUrl: String?
	@Published var isLoggedIn: Bool = false
	@Published var externalUserId: String?

	@Published var isFormValid: Bool = false
	@Published var shouldProceedToFeed: Bool = false

	@Published var spawnUser: User? {
		didSet {
			if spawnUser != nil {
				shouldNavigateToFeedView = true
			}
		}
	}

	@Published var shouldNavigateToFeedView: Bool = false

	@Published var hasCheckedSpawnUserExistance: Bool = false

	private var apiService: IAPIService

	private init(apiService: IAPIService){
		self.apiService = apiService
		check()
		Task {
			await spawnFetchUserIfAlreadyExists()
		}
	}

	func checkStatus(){
		if(GIDSignIn.sharedInstance.currentUser != nil){
			let user = GIDSignIn.sharedInstance.currentUser
			guard let user = user else { return }
			self.fullName = user.profile?.name
			self.givenName = user.profile?.givenName
			self.familyName = user.profile?.familyName
			self.email = user.profile?.email
			self.profilePicUrl = user.profile!.imageURL(withDimension: 100)!.absoluteString
			self.isLoggedIn = true
			self.externalUserId = user.userID
		}else{
			self.isLoggedIn = false
			self.givenName = ""
			self.profilePicUrl =  ""
			self.fullName = nil
			self.familyName = nil
			self.email = nil
			self.externalUserId = nil
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
			self.profilePicUrl = user.profile?.imageURL(withDimension: 100)?.absoluteString ?? ""
			self.fullName = user.profile?.name
			self.givenName = user.profile?.givenName
			self.familyName = user.profile?.familyName
			self.email = user.profile?.email
			self.isLoggedIn = true
			self.externalUserId = user.userID
		}
	}

	func signOut(){
		GIDSignIn.sharedInstance.signOut()
		self.checkStatus()
	}

	func spawnFetchUserIfAlreadyExists() async -> Void {
		if let url = URL(string: APIService.baseURL + "oauth/sign-in") {
			do {
				guard let unwrappedExternalUserId = self.externalUserId else { return } // logic might be off with this `return`
				guard let unwrappedEmail = self.email else { return } // logic might be off with this `return`
				let fetchedSpawnUser: User = try await self.apiService.fetchData(
					from: url,
					parameters: ["externalUserId": unwrappedExternalUserId, "email": unwrappedEmail]
				)

				await MainActor.run {
					self.spawnUser = fetchedSpawnUser
				}
			} catch {
				print(apiService.errorMessage ?? "")
			}
			await MainActor.run {
				self.hasCheckedSpawnUserExistance = true
			}
		}
	}

	func spawnSignIn(username: String, profilePicture: String, firstName: String, lastName: String) async {
		guard let unwrappedEmail = self.email else { return }
		let newUser = User(
			id: UUID(),
			username: username,
			profilePicture: profilePicture,
			firstName: firstName,
			lastName: lastName,
			bio: "",
			email: unwrappedEmail 
		)

		if let url = URL(string: APIService.baseURL + "oauth/make-user") {
			do {
				var parameters: [String: String]? = [:]

				if let unwrappedExternalUserId = externalUserId {
					parameters = ["externalUserId": unwrappedExternalUserId]
				}

				let fetchedAuthenticatedSpawnUser: User = try await self.apiService.sendData(newUser, to: url, parameters: parameters)

				await MainActor.run {
					self.spawnUser = fetchedAuthenticatedSpawnUser
				}

				print("User created successfully.")
			} catch {
				print("Error creating the user: \(error.localizedDescription)")
				print(apiService.errorMessage ?? "")
			}
		} else {
			print("Invalid URL for user creation.")
		}
	}

	func setShouldNavigateToFeedView() -> Void {
		shouldNavigateToFeedView = isLoggedIn && spawnUser != nil && isFormValid
	}
}

//
//  ContactsService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-30.
//

import Contacts
import Foundation
import SwiftUI

struct Contact {
	let id: String
	let name: String
	let phoneNumbers: [String]
}

struct ContactsOnSpawn {
	let contact: Contact
	let spawnUser: BaseUserDTO
}

@MainActor
class ContactsService: ObservableObject {
	static let shared = ContactsService()

	@Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
	@Published var contacts: [Contact] = []
	@Published var contactsOnSpawn: [ContactsOnSpawn] = []
	@Published var isLoading: Bool = false
	@Published var errorMessage: String?

	private let contactStore = CNContactStore()
	private let apiService: IAPIService

	private init() {
		// Use MockAPIService if in mocking mode, otherwise use regular APIService
		self.apiService =
			MockAPIService.isMocking ? MockAPIService() : APIService()
		self.authorizationStatus = CNContactStore.authorizationStatus(
			for: .contacts
		)
	}

	// MARK: - Permission Management

	func requestContactsPermission() async -> Bool {
		do {
			let granted = try await contactStore.requestAccess(for: .contacts)
			await MainActor.run {
				self.authorizationStatus = CNContactStore.authorizationStatus(
					for: .contacts
				)
			}
			return granted
		} catch {
			await MainActor.run {
				self.errorMessage =
					"Failed to request contacts permission: \(error.localizedDescription)"
			}
			return false
		}
	}

	// MARK: - Contacts Access

	func loadContacts() async {
		guard authorizationStatus == .authorized else {
			await MainActor.run {
				self.errorMessage = "Contacts access not authorized"
			}
			return
		}

		await MainActor.run {
			self.isLoading = true
			self.errorMessage = nil
		}

		let keysToFetch: [CNKeyDescriptor] = [
			CNContactGivenNameKey as CNKeyDescriptor,
			CNContactFamilyNameKey as CNKeyDescriptor,
			CNContactPhoneNumbersKey as CNKeyDescriptor,
		]

		let request = CNContactFetchRequest(keysToFetch: keysToFetch)

		do {
			// Move contacts enumeration to background thread to avoid blocking UI
			let fetchedContacts = try await withCheckedThrowingContinuation { continuation in
				Task.detached {
					var contacts: [Contact] = []
					
					do {
						try await self.contactStore.enumerateContacts(with: request) {
							(contact, stop) in
							let phoneNumbers = contact.phoneNumbers.compactMap {
								phoneNumber in
								self.cleanPhoneNumber(phoneNumber.value.stringValue)
							}.filter { !$0.isEmpty }

							// Only include contacts that have phone numbers
							if !phoneNumbers.isEmpty {
								let fullName = "\(contact.givenName) \(contact.familyName)"
									.trimmingCharacters(in: .whitespacesAndNewlines)
								let displayName =
									fullName.isEmpty ? "Unknown Contact" : fullName

								let contactItem = Contact(
									id: contact.identifier,
									name: displayName,
									phoneNumbers: phoneNumbers
								)
								contacts.append(contactItem)
							}
						}
						continuation.resume(returning: contacts)
					} catch {
						continuation.resume(throwing: error)
					}
				}
			}

			await MainActor.run {
				self.contacts = fetchedContacts.sorted {
					$0.name.localizedCaseInsensitiveCompare($1.name)
						== .orderedAscending
				}
				self.isLoading = false
			}

		} catch {
			await MainActor.run {
				self.errorMessage =
					"Failed to load contacts: \(error.localizedDescription)"
				self.isLoading = false
			}
		}
	}

	// MARK: - Cross-Reference with Spawn Users

	func findContactsOnSpawn(userId: UUID) async {
		if contacts.isEmpty {
			await loadContacts()
			if contacts.isEmpty {
				return
			}
		}

		await MainActor.run {
			self.isLoading = true
			self.errorMessage = nil
		}

		// Extract all phone numbers from contacts with contact mapping
		var phoneNumberToContact: [String: Contact] = [:]
		for contact in contacts {
			print("📱 CONTACT: \(contact.name)")
			for phoneNumber in contact.phoneNumbers {
				print("  📞 Original phone: '\(phoneNumber)'")
				phoneNumberToContact[phoneNumber] = contact
			}
		}

		let allPhoneNumbers = Array(phoneNumberToContact.keys)
		print("🔄 TOTAL PHONE NUMBERS TO SEND: \(allPhoneNumbers.count)")
		for (index, phoneNumber) in allPhoneNumbers.enumerated() {
			print("  [\(index)] '\(phoneNumber)'")
		}

		do {
			// Call backend API to cross-reference phone numbers
			let existingUsers = try await crossReferencePhoneNumbers(
				phoneNumbers: allPhoneNumbers,
				requestingUserId: userId
			)

			print("✅ BACKEND RETURNED \(existingUsers.count) USERS")
			for user in existingUsers {
				print("  - \(user.username ?? "No username") (\(user.name ?? "No name"))")
			}

			// Since the backend has successfully matched phone numbers to users,
			// but doesn't return the phone numbers for privacy, we need to
			// create ContactsOnSpawn entries. We'll use a simple approach:
			// each matched user gets a contact entry with their Spawn profile info
			var matchedContacts: [ContactsOnSpawn] = []

			for user in existingUsers {
				// Try to find the best matching contact by name similarity
				var bestMatchContact: Contact?
				var bestMatchScore: Double = 0.0
				
				let userName = (user.name ?? user.username ?? "Unknown").lowercased()
				let userFirstName = userName.components(separatedBy: " ").first ?? ""
				
				for contact in contacts {
					let contactName = contact.name.lowercased()
					let contactFirstName = contactName.components(separatedBy: " ").first ?? ""
					
					// Calculate similarity score
					var score: Double = 0.0
					
					// Exact name match gets highest score
					if contactName == userName {
						score = 1.0
					}
					// First name match gets good score
					else if contactFirstName == userFirstName && !userFirstName.isEmpty {
						score = 0.8
					}
					// Partial name match gets moderate score
					else if contactName.contains(userFirstName) || userName.contains(contactFirstName) {
						score = 0.6
					}
					
					if score > bestMatchScore {
						bestMatchScore = score
						bestMatchContact = contact
					}
				}

				// Create contact entry - use matched contact if found, otherwise create one
				let finalContact = bestMatchContact ?? Contact(
					id: user.id.uuidString,
					                name: user.name ?? user.username ?? "Unknown User",
					phoneNumbers: []  // Don't expose phone numbers for privacy
				)

				matchedContacts.append(
					ContactsOnSpawn(
						contact: finalContact,
						spawnUser: user
					)
				)
			}

			await MainActor.run {
				self.contactsOnSpawn = matchedContacts.sorted {
					$0.contact.name.localizedCaseInsensitiveCompare(
						$1.contact.name
					) == .orderedAscending
				}
				self.isLoading = false
			}

		} catch {
			await MainActor.run {
				self.errorMessage =
					"Failed to find contacts on Spawn: \(error.localizedDescription)"
				self.isLoading = false
			}
		}
	}

	// MARK: - Helper Methods

	private nonisolated func cleanPhoneNumber(_ phoneNumber: String) -> String {
		print("🧹 CLEANING PHONE: '\(phoneNumber)'")
		
		// Check if it's obviously not a phone number
		if phoneNumber.contains("@") || 
		   phoneNumber.contains("-") && phoneNumber.count > 20 ||
		   phoneNumber.range(of: "[a-zA-Z]", options: .regularExpression) != nil && !phoneNumber.contains("@") {
			print("  REJECTED: Not a valid phone number format")
			return ""
		}
		
		// Remove all non-numeric characters except +
		let cleaned = phoneNumber.replacingOccurrences(of: "[^+\\d]", with: "", options: .regularExpression)
		print("  Step 1 - cleaned format: '\(cleaned)'")
		
		// Check minimum length
		let digitsOnly = cleaned.replacingOccurrences(of: "+", with: "")
		if digitsOnly.count < 7 || digitsOnly.count > 15 {
			print("  REJECTED: Invalid digit count (\(digitsOnly.count))")
			return ""
		}
		
		// If it already has a + prefix, keep it as-is
		if cleaned.hasPrefix("+") {
			print("  RESULT: Keeping international format: '\(cleaned)'")
			return cleaned
		}
		
		// For numbers without + prefix, preserve them as entered but clean formatting
		// Don't assume any country code - let the backend handle matching flexibility
		print("  RESULT: Preserving without country assumption: '\(digitsOnly)'")
		return digitsOnly
	}

	// MARK: - API Calls

	private func crossReferencePhoneNumbers(
		phoneNumbers: [String],
		requestingUserId: UUID
	) async throws -> [BaseUserDTO] {
		print("🌐 CALLING CROSS-REFERENCE API")
		print("  📞 Phone numbers to send: \(phoneNumbers.count)")
		for (index, phone) in phoneNumbers.enumerated() {
			print("    [\(index)] '\(phone)'")
		}
		print("  👤 Requesting user ID: \(requestingUserId)")
		
		// Create the request body
		let requestBody = ContactCrossReferenceRequestDTO(
			phoneNumbers: phoneNumbers,
			requestingUserId: requestingUserId
		)

		guard
			let url = URL(
				string: APIService.baseURL + "users/contacts/cross-reference"
			)
		else {
			throw APIError.URLError
		}

		print("🔗 API URL: \(url)")
		
		let result: ContactCrossReferenceResponseDTO? =
			try await apiService.sendData(
				requestBody,
				to: url,
				parameters: nil
			)

		guard let result = result else {
			print("❌ API returned nil result")
			throw APIError.invalidData
		}

		print("✅ API SUCCESS: Returned \(result.users.count) users")
		return result.users
	}
}

// MARK: - DTOs for API

struct ContactCrossReferenceRequestDTO: Codable {
	let phoneNumbers: [String]
	let requestingUserId: UUID
}

struct ContactCrossReferenceResponseDTO: Codable {
	let users: [BaseUserDTO]
}

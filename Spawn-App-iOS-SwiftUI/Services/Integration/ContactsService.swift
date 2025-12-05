//
//  ContactsService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-30.
//

@preconcurrency import Contacts
import Foundation
import SwiftUI

struct Contact: Sendable {
	let id: String
	let name: String
	let phoneNumbers: [String]
}

struct ContactsOnSpawn: Sendable {
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
	private let dataService: DataService

	private init() {
		self.dataService = DataService.shared
		self.authorizationStatus = CNContactStore.authorizationStatus(
			for: .contacts
		)
	}

	// MARK: - Permission Management

	func requestContactsPermission() async -> Bool {
		do {
			let granted = try await contactStore.requestAccess(for: .contacts)
			self.authorizationStatus = CNContactStore.authorizationStatus(
				for: .contacts
			)
			return granted
		} catch {
			self.errorMessage =
				"Failed to request contacts permission: \(error.localizedDescription)"
			return false
		}
	}

	// MARK: - Contacts Access

	func loadContacts() async {
		guard authorizationStatus == .authorized else {
			self.errorMessage = "Contacts access not authorized"
			return
		}

		self.isLoading = true
		self.errorMessage = nil

		let keysToFetch: [CNKeyDescriptor] = [
			CNContactGivenNameKey as CNKeyDescriptor,
			CNContactFamilyNameKey as CNKeyDescriptor,
			CNContactPhoneNumbersKey as CNKeyDescriptor,
		]

		let request = CNContactFetchRequest(keysToFetch: keysToFetch)

		do {
			// Create a new contact store for background thread usage
			let fetchedContacts = try await Task.detached { [request] () -> [Contact] in
				var contacts: [Contact] = []
				let backgroundStore = CNContactStore()

				try backgroundStore.enumerateContacts(with: request) {
					(contact, _) in
					let phoneNumbers = contact.phoneNumbers.compactMap {
						phoneNumber in
						ContactsService.cleanPhoneNumber(phoneNumber.value.stringValue)
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
				return contacts
			}.value

			self.contacts = fetchedContacts.sorted {
				$0.name.localizedCaseInsensitiveCompare($1.name)
					== .orderedAscending
			}
			self.isLoading = false

		} catch {
			self.errorMessage =
				"Failed to load contacts: \(error.localizedDescription)"
			self.isLoading = false
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

		self.isLoading = true
		self.errorMessage = nil

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
				let finalContact =
					bestMatchContact
					?? Contact(
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

			self.contactsOnSpawn = matchedContacts.sorted {
				$0.contact.name.localizedCaseInsensitiveCompare(
					$1.contact.name
				) == .orderedAscending
			}
			self.isLoading = false

		} catch {
			self.errorMessage =
				"Failed to find contacts on Spawn: \(error.localizedDescription)"
			self.isLoading = false
		}
	}

	// MARK: - Helper Methods

	/// Cleans and normalizes a phone number string.
	/// Nonisolated because it's a pure function with no MainActor dependencies.
	private nonisolated static func cleanPhoneNumber(_ phoneNumber: String) -> String {
		print("🧹 CLEANING PHONE: '\(phoneNumber)'")

		// Check if it's obviously not a phone number
		if phoneNumber.contains("@") || phoneNumber.contains("-") && phoneNumber.count > 20
			|| phoneNumber.range(of: "[a-zA-Z]", options: .regularExpression) != nil && !phoneNumber.contains("@")
		{
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

		// Use DataService to perform the cross-reference
		let result: DataResult<ContactCrossReferenceResponseDTO> = await dataService.write(
			.crossReferenceContacts(request: requestBody),
			body: requestBody
		)

		switch result {
		case .success(let response, _):
			return response.users
		case .failure(let error):
			print("❌ API returned error: \(error)")
			throw error
		}
	}
}

// MARK: - DTOs for API

struct ContactCrossReferenceRequestDTO: Codable, Sendable {
	let phoneNumbers: [String]
	let requestingUserId: UUID
}

struct ContactCrossReferenceResponseDTO: Codable, Sendable {
	let users: [BaseUserDTO]
}

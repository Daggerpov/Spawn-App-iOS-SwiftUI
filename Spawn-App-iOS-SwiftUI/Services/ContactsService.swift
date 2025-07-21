//
//  ContactsService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by AI Assistant on 2025-01-30.
//

import Foundation
import Contacts
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
        self.apiService = MockAPIService.isMocking ? MockAPIService() : APIService()
        self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    // MARK: - Permission Management
    
    func requestContactsPermission() async -> Bool {
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            await MainActor.run {
                self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            return granted
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to request contacts permission: \(error.localizedDescription)"
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
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var fetchedContacts: [Contact] = []
        
        do {
            try contactStore.enumerateContacts(with: request) { (contact, stop) in
                let phoneNumbers = contact.phoneNumbers.compactMap { phoneNumber in
                    self.cleanPhoneNumber(phoneNumber.value.stringValue)
                }.filter { !$0.isEmpty }
                
                // Only include contacts that have phone numbers
                if !phoneNumbers.isEmpty {
                    let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                    let displayName = fullName.isEmpty ? "Unknown Contact" : fullName
                    
                    let contactItem = Contact(
                        id: contact.identifier,
                        name: displayName,
                        phoneNumbers: phoneNumbers
                    )
                    fetchedContacts.append(contactItem)
                }
            }
            
            await MainActor.run {
                self.contacts = fetchedContacts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load contacts: \(error.localizedDescription)"
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
            for phoneNumber in contact.phoneNumbers {
                phoneNumberToContact[phoneNumber] = contact
            }
        }
        
        let allPhoneNumbers = Array(phoneNumberToContact.keys)
        
        do {
            // Call backend API to cross-reference phone numbers
            let existingUsers = try await crossReferencePhoneNumbers(
                phoneNumbers: allPhoneNumbers,
                requestingUserId: userId
            )
            
            // Create a mapping of phone numbers to users for quick lookup
            var phoneNumberToUser: [String: BaseUserDTO] = [:]
            for user in existingUsers {
                // Since the backend doesn't return phone numbers for privacy,
                // we need to match based on other criteria or trust the backend's matching
                // For now, we'll use the user data as received from backend
                phoneNumberToUser[user.id.uuidString] = user
            }
            
            // Match contacts with Spawn users
            var matchedContacts: [ContactsOnSpawn] = []
            
            // Since the backend has already done the phone number matching,
            // we'll create matches based on the returned users
            // We'll try to find the best contact match for each user
            for user in existingUsers {
                // Try to find a contact that could match this user
                // This is a best-effort approach since we don't have exact phone mapping
                var bestMatchContact: Contact?
                
                // Try matching by name similarity
                let userName = user.name ?? user.username
                for contact in contacts {
                    if contact.name.localizedCaseInsensitiveContains(userName.components(separatedBy: " ").first ?? "") ||
                       userName.localizedCaseInsensitiveContains(contact.name.components(separatedBy: " ").first ?? "") {
                        bestMatchContact = contact
                        break
                    }
                }
                
                // If no name match found, create a contact representation based on user info
                let finalContact = bestMatchContact ?? Contact(
                    id: user.id.uuidString,
                    name: user.name ?? user.username,
                    phoneNumbers: [] // Don't expose phone numbers for privacy
                )
                
                matchedContacts.append(ContactsOnSpawn(
                    contact: finalContact,
                    spawnUser: user
                ))
            }
            
            await MainActor.run {
                self.contactsOnSpawn = matchedContacts.sorted { $0.contact.name.localizedCaseInsensitiveCompare($1.contact.name) == .orderedAscending }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to find contacts on Spawn: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func cleanPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all non-numeric characters
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // If it starts with 1 and has 11 digits, remove the 1 (US country code)
        if cleaned.count == 11 && cleaned.hasPrefix("1") {
            return String(cleaned.dropFirst())
        }
        
        return cleaned
    }
    
    // MARK: - API Calls
    
    private func crossReferencePhoneNumbers(phoneNumbers: [String], requestingUserId: UUID) async throws -> [BaseUserDTO] {
        // Create the request body
        let requestBody = ContactCrossReferenceRequestDTO(
            phoneNumbers: phoneNumbers,
            requestingUserId: requestingUserId
        )
        
        guard let url = URL(string: APIService.baseURL + "users/contacts/cross-reference") else {
            throw APIError.URLError
        }
        
        let result: ContactCrossReferenceResponseDTO? = try await apiService.sendData(
            requestBody,
            to: url,
            parameters: nil
        )
        
        guard let result = result else {
            throw APIError.invalidData
        }
        
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
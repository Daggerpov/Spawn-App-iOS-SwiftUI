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
                self.contacts = fetchedContacts.sorted { $0.name < $1.name }
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
        
        // Extract all phone numbers from contacts
        let allPhoneNumbers = contacts.flatMap { $0.phoneNumbers }
        let uniquePhoneNumbers = Array(Set(allPhoneNumbers))
        
        do {
            // Call backend API to cross-reference phone numbers
            let existingUsers = try await crossReferencePhoneNumbers(
                phoneNumbers: uniquePhoneNumbers,
                requestingUserId: userId
            )
            
            // Since the backend already matched phone numbers and returned only matching users,
            // we need to create placeholder contact info for display purposes
            var matchedContacts: [ContactsOnSpawn] = []
            
            for user in existingUsers {
                // Create a placeholder contact since we don't have the exact contact mapping
                // The backend has already done the phone number matching for us
                let placeholderContact = Contact(
                    id: user.id.uuidString,
                    name: user.name ?? user.username,
                    phoneNumbers: [] // We don't expose phone numbers for privacy
                )
                
                matchedContacts.append(ContactsOnSpawn(
                    contact: placeholderContact,
                    spawnUser: user
                ))
            }
            
            await MainActor.run {
                self.contactsOnSpawn = matchedContacts.sorted { $0.contact.name < $1.contact.name }
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
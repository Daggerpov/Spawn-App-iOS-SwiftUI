//
//  ContactImportView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-30.
//

import SwiftUI
import Contacts

struct ContactImportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userAuth = UserAuthViewModel.shared
    @StateObject private var contactsService = ContactsService.shared
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var searchText: String = ""
    @State private var addedFriends: Set<UUID> = []
    @State private var invitedContacts: Set<String> = []
    @State private var showPermissionDeniedAlert: Bool = false
    @State private var showSpawnContactsSection: Bool = true
    @State private var showSuggestedContactsSection: Bool = true
    @State private var isCompletingContactImport: Bool = false
    
    var filteredSpawnContacts: [ContactsOnSpawn] {
        let contacts = contactsService.contactsOnSpawn
        if searchText.isEmpty {
            return contacts.sorted { $0.contact.name.localizedCaseInsensitiveCompare($1.contact.name) == .orderedAscending }
        } else {
            return contacts
                .filter { $0.contact.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.contact.name.localizedCaseInsensitiveCompare($1.contact.name) == .orderedAscending }
        }
    }
    
    var filteredRegularContacts: [Contact] {
        let spawnContactIds = Set(contactsService.contactsOnSpawn.map { $0.contact.id })
        let regularContacts = contactsService.contacts.filter { !spawnContactIds.contains($0.id) }
        
        if searchText.isEmpty {
            return regularContacts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            return regularContacts
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    var groupedRegularContacts: [(String, [Contact])] {
        let contacts = filteredRegularContacts
        let grouped = Dictionary(grouping: contacts) { contact in
            String(contact.name.prefix(1).uppercased())
        }
        return grouped.sorted { first, second in
            let firstChar = first.key
            let secondChar = second.key
            
            // Check if characters are alphabetic
            let firstIsAlpha = firstChar.rangeOfCharacter(from: CharacterSet.letters) != nil
            let secondIsAlpha = secondChar.rangeOfCharacter(from: CharacterSet.letters) != nil
            
            // If one is alphabetic and the other isn't, alphabetic comes first
            if firstIsAlpha && !secondIsAlpha {
                return true
            } else if !firstIsAlpha && secondIsAlpha {
                return false
            } else {
                // Both are alphabetic or both are non-alphabetic, use normal comparison
                return firstChar < secondChar
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {
                    // Clear any error states when going back
                    userAuth.clearAllErrors()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Title Section
            VStack(alignment: .leading, spacing: 20) {
                Text("Bring your Friends")
                    .font(Font.custom("Onest", size: 32).weight(.bold))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                
                Text("Import your contacts to invite friends directly to Spawn.")
                    .font(Font.custom("Onest", size: 20))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 40)
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
                
                TextField("Search contacts", text: $searchText)
                    .font(Font.custom("Onest", size: 16).weight(.medium))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .background(universalBackgroundColor(from: themeService, environment: colorScheme))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(universalPlaceHolderTextColor(from: themeService, environment: colorScheme), lineWidth: 0.50)
            )
            .padding(.horizontal, 26)
            .padding(.top, 32)
            
            // Contacts List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Already on Spawn Section
                    if !filteredSpawnContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSpawnContactsSection.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Already on Spawn")
                                        .font(Font.custom("Onest", size: 16).weight(.medium))
                                        .foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
                                    
                                    Spacer()
                                    
                                    Image(systemName: showSpawnContactsSection ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showSpawnContactsSection {
                                ForEach(filteredSpawnContacts, id: \.contact.id) { contactOnSpawn in
                                    SpawnContactRow(
                                        contactOnSpawn: contactOnSpawn,
                                        isAdded: addedFriends.contains(contactOnSpawn.spawnUser.id),
                                        onAdd: {
                                            addedFriends.insert(contactOnSpawn.spawnUser.id)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Suggested/Invite Section
                    if !filteredRegularContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSuggestedContactsSection.toggle()
                                }
                            }) {
                                HStack {
                                    Text(filteredSpawnContacts.isEmpty ? "Bring onto Spawn" : "Invite to Spawn")
                                        .font(Font.custom("Onest", size: 16).weight(.medium))
                                        .foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
                                    
                                    Spacer()
                                    
                                    Image(systemName: showSuggestedContactsSection ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showSuggestedContactsSection {
                                ForEach(groupedRegularContacts, id: \.0) { letter, contactsInSection in
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Section header
                                        HStack {
                                            Text(letter)
                                                .font(Font.custom("Onest", size: 18).weight(.semibold))
                                                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                            
                                            Rectangle()
                                                .fill(universalPlaceHolderTextColor(from: themeService, environment: colorScheme).opacity(0.3))
                                                .frame(height: 1)
                                        }
                                        .padding(.top, letter == groupedRegularContacts.first?.0 ? 0 : 12)
                                        
                                        // Contacts in this section
                                        ForEach(contactsInSection, id: \.id) { contact in
                                            InviteContactRow(
                                                contact: contact,
                                                isInvited: invitedContacts.contains(contact.id),
                                                onInvite: {
                                                    invitedContacts.insert(contact.id)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 24)
                .padding(.bottom, 120) // Space for continue button
            }
            
            Spacer()
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .overlay(
            // Continue Button - Fixed at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    Task {
                        isCompletingContactImport = true
                        await userAuth.completeContactImport()
                        isCompletingContactImport = false
                    }
                }) {
                    OnboardingButtonCoreView("Continue") {
                        isCompletingContactImport ? Color.gray : figmaIndigo
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isCompletingContactImport)
                .padding(.horizontal, 10)
                .padding(.bottom, 34)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [universalBackgroundColor(from: themeService, environment: colorScheme).opacity(0), universalBackgroundColor(from: themeService, environment: colorScheme)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                )
            }
        )
        .navigationBarHidden(true)
        .alert("Contacts Permission Denied", isPresented: $showPermissionDeniedAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Skip", role: .cancel) {
                Task {
                    isCompletingContactImport = true
                    await userAuth.completeContactImport()
                    isCompletingContactImport = false
                }
            }
        } message: {
            Text("To find friends on Spawn, we need access to your contacts. You can enable this in Settings.")
        }
        .onAppear {
            // Clear any previous error state when this view appears
            userAuth.clearAllErrors()
            requestContactsAndLoad()
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestContactsAndLoad() {
        Task {
            // Request permission first
            let granted = await contactsService.requestContactsPermission()
            
            if granted {
                await loadAndCrossReferenceContacts()
            } else {
                showPermissionDeniedAlert = true
            }
        }
    }
    
    private func loadAndCrossReferenceContacts() async {
        guard let userId = userAuth.spawnUser?.id else { return }
        
        // Load contacts first
        await contactsService.loadContacts()
        
        // Then cross-reference with Spawn users
        await contactsService.findContactsOnSpawn(userId: userId)
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Contact Row Components
// All contact row view structs have been moved to separate files in ContactImportView/
// - SpawnContactRow.swift
// - InviteContactRow.swift

#Preview {
    ContactImportView()
} 

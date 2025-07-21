//
//  ContactImportView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by AI Assistant on 2025-01-30.
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
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        isCompletingContactImport = true
                        await userAuth.completeContactImport()
                        isCompletingContactImport = false
                    }
                }) {
                    Text("Skip for now")
                        .font(Font.custom("Onest", size: 14).weight(.bold))
                        .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                }
                .disabled(isCompletingContactImport)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            // Title Section
            VStack(alignment: .leading, spacing: 20) {
                Text("Bring your Friends")
                    .font(Font.custom("Onest", size: 32).weight(.bold))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                
                Text("Import your contacts to invite friends directly to Spawn.")
                    .font(Font.custom("Onest", size: 20))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.top, 40)
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                
                TextField("Search contacts", text: $searchText)
                    .font(Font.custom("Onest", size: 16).weight(.medium))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.56, green: 0.52, blue: 0.52), lineWidth: 0.50)
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
                                        .foregroundColor(Color(red: 0.40, green: 0.38, blue: 0.38))
                                    
                                    Spacer()
                                    
                                    Image(systemName: showSpawnContactsSection ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
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
                                    Text(filteredSpawnContacts.isEmpty ? "Suggested" : "Invite to Spawn")
                                        .font(Font.custom("Onest", size: 16).weight(.medium))
                                        .foregroundColor(Color(red: 0.40, green: 0.38, blue: 0.38))
                                    
                                    Spacer()
                                    
                                    Image(systemName: showSuggestedContactsSection ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
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
                                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                                            
                                            Rectangle()
                                                .fill(Color(red: 0.40, green: 0.38, blue: 0.38).opacity(0.3))
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
        .background(Color.white)
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
                        gradient: Gradient(colors: [Color.white.opacity(0), Color.white]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                )
            }
        )
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $userAuth.shouldNavigateToUserToS) {
            UserToS()
        }
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

struct SpawnContactRow: View {
    let contactOnSpawn: ContactsOnSpawn
    let isAdded: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: contactOnSpawn.spawnUser.profilePicture.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                    .overlay(
                        Text(String(contactOnSpawn.contact.name.prefix(1)))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.25), radius: 4.06, y: 1.62)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contactOnSpawn.contact.name)
                    .font(Font.custom("Onest", size: 14).weight(.semibold))
                    .foregroundColor(.black)
                
                Text("@\(contactOnSpawn.spawnUser.username)")
                    .font(Font.custom("Onest", size: 12))
                    .foregroundColor(Color(red: 0.40, green: 0.38, blue: 0.38))
            }
            
            Spacer()
            
            Button(action: onAdd) {
                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.40, green: 0.38, blue: 0.38))
                }
            }
            .disabled(isAdded)
        }
        .padding(.vertical, 8)
    }
}

struct InviteContactRow: View {
    let contact: Contact
    let isInvited: Bool
    let onInvite: () -> Void
    @State private var isAnimating: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture Placeholder
            Circle()
                .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                .overlay(
                    Text(String(contact.name.prefix(1)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
                .frame(width: 36, height: 36)
                .shadow(color: Color.black.opacity(0.25), radius: 4.06, y: 1.62)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(Font.custom("Onest", size: 14).weight(.semibold))
                    .foregroundColor(.black)
                
                if let phoneNumber = contact.phoneNumbers.first {
                    Text(phoneNumber)
                        .font(Font.custom("Onest", size: 12))
                        .foregroundColor(Color(red: 0.40, green: 0.38, blue: 0.38))
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
                
                // Trigger the invite action after animation starts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onInvite()
                }
            }) {
                HStack(spacing: 6) {
                    if isInvited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text("Invite")
                            .font(.onestMedium(size: 14))
                    }
                }
                .foregroundColor(isInvited ? .white : Color(red: 0.40, green: 0.38, blue: 0.38))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isInvited ? .green : Color.clear)
                        .animation(.easeInOut(duration: 0.3), value: isInvited)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isInvited ? .green : Color(red: 0.40, green: 0.38, blue: 0.38), lineWidth: 1)
                        .animation(.easeInOut(duration: 0.3), value: isInvited)
                )
                .scaleEffect(isAnimating && !isInvited ? 0.95 : 1.0)
            }
            .disabled(isInvited)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContactImportView()
} 

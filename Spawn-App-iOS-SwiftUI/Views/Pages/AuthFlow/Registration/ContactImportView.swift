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
    
    @State private var isLoading: Bool = false
    @State private var showPermissionDeniedAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {
                    userAuth.resetAuthFlow()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
                Spacer()
                
                // Skip button
                Button(action: {
                    userAuth.shouldNavigateToUserToS = true
                }) {
                    Text("Skip")
                        .font(.onestRegular(size: 16))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
            
            // Main Content
            VStack(spacing: 32) {
                // Title and Subtitle
                VStack(spacing: 16) {
                    Text("Find Your Friends")
                        .font(heading1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .multilineTextAlignment(.center)
                    
                    Text("Let's see who from your contacts is already on Spawn so you can connect with them.")
                        .font(body1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                // Contacts Icon or Results
                if contactsService.contactsOnSpawn.isEmpty && !contactsService.isLoading {
                    // Show contacts icon
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 80))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.6))
                        
                        Text("Tap below to find friends who are already using Spawn")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                } else if contactsService.isLoading {
                    // Show loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: universalAccentColor(from: themeService, environment: colorScheme)))
                            .scaleEffect(1.5)
                        
                        Text("Checking your contacts...")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.8))
                    }
                } else {
                    // Show results
                    ContactsResultsView(contactsOnSpawn: contactsService.contactsOnSpawn)
                }
                
                // Error Message
                if let errorMessage = contactsService.errorMessage {
                    Text(errorMessage)
                        .font(.onestRegular(size: 15))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Import Contacts or Continue Button
                if contactsService.contactsOnSpawn.isEmpty && !contactsService.isLoading {
                    Button(action: {
                        importContacts()
                    }) {
                        OnboardingButtonCoreView("Import Contacts") {
                            figmaIndigo
                        }
                    }
                    .padding(.top, -16)
                    .padding(.horizontal, -22)
                } else if !contactsService.contactsOnSpawn.isEmpty {
                    Button(action: {
                        userAuth.shouldNavigateToUserToS = true
                    }) {
                        OnboardingButtonCoreView("Continue") {
                            figmaIndigo
                        }
                    }
                    .padding(.top, -16)
                    .padding(.horizontal, -22)
                }
            }
            
            Spacer()
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $userAuth.shouldNavigateToUserToS) {
            UserToS()
        }
        .alert("Contacts Permission Denied", isPresented: $showPermissionDeniedAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Skip", role: .cancel) {
                userAuth.shouldNavigateToUserToS = true
            }
        } message: {
            Text("To find friends on Spawn, we need access to your contacts. You can enable this in Settings.")
        }
        .onAppear {
            // Check if we already have permission
            if contactsService.authorizationStatus == .authorized {
                Task {
                    await loadAndCrossReferenceContacts()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func importContacts() {
        Task {
            isLoading = true
            
            // Request permission first
            let granted = await contactsService.requestContactsPermission()
            
            if granted {
                await loadAndCrossReferenceContacts()
            } else {
                showPermissionDeniedAlert = true
            }
            
            isLoading = false
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

// MARK: - Contacts Results View

struct ContactsResultsView: View {
    let contactsOnSpawn: [ContactsOnSpawn]
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            if contactsOnSpawn.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.6))
                    
                    Text("No friends found")
                        .font(.onestSemiBold(size: 18))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    
                    Text("None of your contacts are on Spawn yet. Invite them to join!")
                        .font(.onestRegular(size: 14))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Found \(contactsOnSpawn.count) friend\(contactsOnSpawn.count == 1 ? "" : "s")")
                            .font(.onestSemiBold(size: 18))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        
                        Text("These contacts are already on Spawn")
                            .font(.onestRegular(size: 14))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
                    }
                    
                    // Contacts List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(contactsOnSpawn, id: \.contact.id) { contactOnSpawn in
                                ContactRowView(contactOnSpawn: contactOnSpawn)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
    }
}

// MARK: - Contact Row View

struct ContactRowView: View {
    let contactOnSpawn: ContactsOnSpawn
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: contactOnSpawn.spawnUser.profilePicture.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Names
            VStack(alignment: .leading, spacing: 2) {
                Text(contactOnSpawn.contact.name)
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                
                Text("@\(contactOnSpawn.spawnUser.username)")
                    .font(.onestRegular(size: 14))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
            }
            
            Spacer()
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.05))
        )
    }
}

#Preview {
    ContactImportView()
} 
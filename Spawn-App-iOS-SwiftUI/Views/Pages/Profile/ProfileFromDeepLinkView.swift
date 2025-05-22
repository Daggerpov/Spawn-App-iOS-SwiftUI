//
//  ProfileFromDeepLinkView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI

struct ProfileFromDeepLinkView: View {
    let userId: UUID
    
    @StateObject private var viewModel = UserViewModel()
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading profile...")
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Error loading profile")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: loadUserProfile) {
                        Text("Try Again")
                            .padding()
                            .background(universalAccentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 16)
                    }
                }
                .padding()
            } else if let user = viewModel.user {
                // Show the actual profile view with the user data and back button enabled
                ProfileView(user: user, showBackButton: true)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.user?.username ?? "Profile")
        .onAppear {
            loadUserProfile()
        }
    }
    
    private func loadUserProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch the user profile by ID
                let result = try await viewModel.fetchUser(userId: userId)
                
                await MainActor.run {
                    isLoading = false
                    // Success is handled by the viewModel.user being set
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Could not load the profile. \(error.localizedDescription)"
                }
            }
        }
    }
}

// A simple ViewModel to fetch user data
class UserViewModel: ObservableObject {
    @Published var user: BaseUserDTO?
    
    func fetchUser(userId: UUID) async throws -> Bool {
        // Replace with your actual API service
        let userService = UserService.shared
        
        do {
            let fetchedUser = try await userService.getUserById(userId: userId)
            
            await MainActor.run {
                self.user = fetchedUser
            }
            
            return true
        } catch {
            print("Error fetching user: \(error)")
            throw error
        }
    }
}

#Preview {
    ProfileFromDeepLinkView(userId: UUID())
} 
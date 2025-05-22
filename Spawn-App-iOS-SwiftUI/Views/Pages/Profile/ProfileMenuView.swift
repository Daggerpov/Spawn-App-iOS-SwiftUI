//
//  ProfileMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-12.
//

import SwiftUI

struct ProfileMenuView: View {
    let user: Nameable
    @Binding var showTagDialog: Bool
    @Binding var showRemoveFriendConfirmation: Bool
    @Binding var showReportDialog: Bool
    @Binding var showBlockDialog: Bool
    let isFriend: Bool
    let copyProfileURL: () -> Void
    let shareProfile: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Menu content
        VStack(spacing: 0) {
            // Menu items container
            VStack(spacing: 0) {
                // Add to Tag option (only visible for friends)
                if isFriend {
                    Button(action: {
                        dismiss()
                        showTagDialog = true
                    }) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(universalAccentColor)
                            
                            Text("Add to Tag")
                                .foregroundColor(universalAccentColor)
                            
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                    }
                    
                    Divider()
                }
                
                // Remove as friend (only if they are a friend)
                if isFriend {
                    Button(action: {
                        dismiss()
                        showRemoveFriendConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.minus")
                                .foregroundColor(universalAccentColor)
                            
                            Text("Remove as friend")
                                .foregroundColor(universalAccentColor)
                            
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                    }
                    
                    Divider()
                }
                
                // Copy profile URL
                Button(action: {
                    copyProfileURL()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(universalAccentColor)
                        
                        Text("Copy profile URL")
                            .foregroundColor(universalAccentColor)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
                
                Divider()
                
                // Share this Profile
                Button(action: {
                    shareProfile()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(universalAccentColor)
                        
                        Text("Share this Profile")
                            .foregroundColor(universalAccentColor)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
                
                Divider()
                
                // Report user
                Button(action: {
                    dismiss()
                    showReportDialog = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        
                        Text("Report user")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
                
                Divider()
                
                // Block user
                Button(action: {
                    dismiss()
                    showBlockDialog = true
                }) {
                    HStack {
                        Image(systemName: "hand.raised.slash")
                            .foregroundColor(.red)
                        
                        Text("Block user")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
            }
            .background(universalBackgroundColor)
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Cancel button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(universalBackgroundColor)
            .cornerRadius(12)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ProfileMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileMenuView(
            user: BaseUserDTO.danielAgapov,
            showTagDialog: .constant(false),
            showRemoveFriendConfirmation: .constant(false),
            showReportDialog: .constant(false),
            showBlockDialog: .constant(false),
            isFriend: true,
            copyProfileURL: {},
            shareProfile: {}
        )
    }
} 

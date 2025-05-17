//
//  ProfileMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-12.
//

import SwiftUI

struct ProfileMenuView: View {
    let user: BaseUserDTO
    @Binding var showTagDialog: Bool
    @Binding var showRemoveFriendConfirmation: Bool
    @Binding var showReportDialog: Bool
    @Binding var showBlockDialog: Bool
    let isFriend: Bool
    let copyProfileURL: () -> Void
    let shareProfile: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFriendToTagView = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
                // Handle at top
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                
                // Header
                Text("@\(user.username)")
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Friend-specific options
                        if isFriend {
                            menuItem(
                                title: "Add Friend to Tag",
                                icon: "tag",
                                color: .blue,
                                action: {
                                    dismiss()
                                    showAddFriendToTagView = true
                                }
                            )
                            
                            menuItem(
                                title: "Remove Friend",
                                icon: "person.badge.minus",
                                color: .orange,
                                action: {
                                    dismiss()
                                    showRemoveFriendConfirmation = true
                                }
                            )
                            
                            Divider()
                                .padding(.vertical, 8)
                        }
                        
                        // General options
                        menuItem(
                            title: "Copy Profile URL",
                            icon: "link",
                            color: .gray,
                            action: {
                                copyProfileURL()
                                dismiss()
                            }
                        )
                        
                        menuItem(
                            title: "Share Profile",
                            icon: "square.and.arrow.up",
                            color: .blue,
                            action: {
                                shareProfile()
                                dismiss()
                            }
                        )
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Moderation options
                        menuItem(
                            title: "Report User",
                            icon: "flag",
                            color: .red,
                            action: {
                                dismiss()
                                showReportDialog = true
                            }
                        )
                        
                        menuItem(
                            title: "Block User",
                            icon: "slash.circle",
                            color: .red,
                            action: {
                                dismiss()
                                showBlockDialog = true
                            }
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Cancel button
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(universalAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $showAddFriendToTagView) {
            AddFriendToTagView(user: user)
        }
    }
    
    private func menuItem(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 14)
        }
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
//
//  FriendsTabMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by AI Assistant on 2025-01-27.
//

import SwiftUI

struct FriendsTabMenuView: View {
    let user: Nameable
    @Binding var showReportDialog: Bool
    @Binding var showBlockDialog: Bool
    let copyProfileURL: () -> Void
    let shareProfile: () -> Void
    let navigateToProfile: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var firstName: String {
        if let name = user.name, !name.isEmpty {
            		return name.components(separatedBy: " ").first ?? user.username ?? "User"
        }
        		return user.username ?? "User"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Menu items container
            VStack(alignment: .leading, spacing: 0) {
                // View Profile
                menuItem(
                    text: "View Profile",
                    icon: "􀉭",
                    textColor: .white,
                    action: {
                        dismiss()
                        navigateToProfile()
                    }
                )
                
                // Share Profile
                menuItem(
                    text: "Share Profile",
                    icon: "􀈂",
                    textColor: .white,
                    action: {
                        dismiss()
                        shareProfile()
                    }
                )
                
                // Report User
                menuItem(
                    text: "Report \(firstName)",
                    icon: "􀌬",
                    textColor: Color(red: 1, green: 0.23, blue: 0.19),
                    action: {
                        dismiss()
                        showReportDialog = true
                    }
                )
                
                // Block User
                menuItem(
                    text: "Block \(firstName)",
                    icon: "􀉽",
                    textColor: Color(red: 1, green: 0.23, blue: 0.19),
                    action: {
                        dismiss()
                        showBlockDialog = true
                    }
                )
            }
            .frame(width: 228)
            .background(Color(red: 0.55, green: 0.55, blue: 0.55))
            .cornerRadius(12)
        }
        .shadow(
            color: Color(red: 0, green: 0, blue: 0, opacity: 0.20),
            radius: 32
        )
    }
    
    private func menuItem(
        text: String,
        icon: String,
        textColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(Font.custom("SF Pro", size: 17))
                    .lineSpacing(22)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text(icon)
                    .font(Font.custom("SF Pro", size: 17))
                    .lineSpacing(22)
                    .foregroundColor(textColor)
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .frame(height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Rectangle()
                .inset(by: -0.25)
                .stroke(
                    textColor == .white 
                    ? Color(red: 0.38, green: 0.35, blue: 0.35)
                    : Color(red: 0.50, green: 0.50, blue: 0.50).opacity(0.55),
                    lineWidth: 0.25
                )
        )
    }
}

#Preview {
    FriendsTabMenuView(
        user: BaseUserDTO.danielAgapov,
        showReportDialog: .constant(false),
        showBlockDialog: .constant(false),
        copyProfileURL: {},
        shareProfile: {},
        navigateToProfile: {}
    )
} 
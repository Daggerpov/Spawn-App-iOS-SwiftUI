//
//  ProfileMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-12.
//

import SwiftUI

struct ProfileMenuView: View {
    let user: Nameable
    @Binding var showRemoveFriendConfirmation: Bool
    @Binding var showReportDialog: Bool
    @Binding var showBlockDialog: Bool
    let isFriend: Bool
    let copyProfileURL: () -> Void
    let shareProfile: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = true
    
    var body: some View {
        MenuContainer {
            if isLoading {
                loadingContent
            } else {
                MenuContent(
                    user: user,
                    showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
                    showReportDialog: $showReportDialog,
                    showBlockDialog: $showBlockDialog,
                    isFriend: isFriend,
                    copyProfileURL: copyProfileURL,
                    shareProfile: shareProfile,
                    dismiss: dismiss
                )
            }
        }
        .onAppear {
            // Simulate a very brief loading state to ensure smooth animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoading = false
            }
        }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 16) {
            ForEach(0..<5) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(universalBackgroundColor)
            .cornerRadius(12)
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// Add shimmer effect modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.white
                        .opacity(0.3)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .white.opacity(0.7), .clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * 2)
                                .offset(x: -geometry.size.width)
                                .offset(x: phase * geometry.size.width)
                        )
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// Container view that provides the background and layout
private struct MenuContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 8) {
            content
                .background(universalBackgroundColor)
                .cornerRadius(12, corners: [.topLeft, .topRight])
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.clear)
    }
}

// Content view that contains the actual menu items
private struct MenuContent: View {
    let user: Nameable
    @Binding var showRemoveFriendConfirmation: Bool
    @Binding var showReportDialog: Bool
    @Binding var showBlockDialog: Bool
    let isFriend: Bool
    let copyProfileURL: () -> Void
    let shareProfile: () -> Void
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 0) {
            menuItems
            
            cancelButton
        }
    }
    
    private var menuItems: some View {
        VStack(spacing: 0) {
            if isFriend {
                menuItem(
                    icon: "person.badge.minus",
                    text: "Remove Friend",
                    color: .red
                ) {
                    dismiss()
                    showRemoveFriendConfirmation = true
                }
                
                Divider()
            }
            
            menuItem(
                icon: "link",
                text: "Copy profile URL",
                color: universalAccentColor
            ) {
                copyProfileURL()
                dismiss()
            }
            
            Divider()
            
            menuItem(
                icon: "square.and.arrow.up",
                text: "Share this Profile",
                color: universalAccentColor
            ) {
                shareProfile()
                dismiss()
            }
            
            Divider()
            
            menuItem(
                icon: "exclamationmark.triangle",
                text: "Report user",
                color: .red
            ) {
                dismiss()
                showReportDialog = true
            }
            
            Divider()
            
            menuItem(
                icon: "hand.raised.slash",
                text: "Block user",
                color: .red
            ) {
                dismiss()
                showBlockDialog = true
            }
        }
    }
    
    private var cancelButton: some View {
        Button(action: { dismiss() }) {
            Text("Cancel")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(universalBackgroundColor)
        .cornerRadius(12)
    }
    
    private func menuItem(
        icon: String,
        text: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(text)
                    .foregroundColor(color)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
    }
}

struct ProfileMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileMenuView(
            user: BaseUserDTO.danielAgapov,
            showRemoveFriendConfirmation: .constant(false),
            showReportDialog: .constant(false),
            showBlockDialog: .constant(false),
            isFriend: true,
            copyProfileURL: {},
            shareProfile: {}
        )
    }
} 

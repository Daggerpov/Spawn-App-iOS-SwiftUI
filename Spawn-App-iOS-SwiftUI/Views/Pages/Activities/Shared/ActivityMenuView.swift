//
//  ActivityMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-27.
//

import SwiftUI

struct ActivityMenuView: View {
    let activity: FullFeedActivityDTO
    @Binding var showReportDialog: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = true
    
    var body: some View {
        ActivityMenuContainer {
            if isLoading {
                loadingContent
            } else {
                ActivityMenuContent(
                    activity: activity,
                    showReportDialog: $showReportDialog,
                    dismiss: dismiss
                )
            }
        }
        .background(universalBackgroundColor)
        .onAppear {
            // Simulate a very brief loading state to ensure smooth animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoading = false
            }
        }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 16) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            // Loading content
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 80)
            
            Spacer()
        }
        .background(universalBackgroundColor)
    }
}

private struct ActivityMenuContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Content
            content
        }
        .background(universalBackgroundColor)
    }
}

private struct ActivityMenuContent: View {
    let activity: FullFeedActivityDTO
    @Binding var showReportDialog: Bool
    let dismiss: DismissAction
    
    private var activityTitle: String {
        activity.title ?? "Activity"
    }
    
    private var creatorName: String {
        activity.creatorUser.name ?? activity.creatorUser.username ?? "User"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Activity info header
            VStack(spacing: 8) {
                Text("\"\(activityTitle)\"")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("by \(creatorName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Menu items
            menuItems
                .background(universalBackgroundColor)
            
            cancelButton
        }
        .background(universalBackgroundColor)
    }
    
    private var menuItems: some View {
        VStack(spacing: 0) {
            menuItem(
                icon: "exclamationmark.triangle",
                text: "Report Activity",
                color: .red
            ) {
                dismiss()
                showReportDialog = true
            }
            .background(universalBackgroundColor)
        }
        .background(universalBackgroundColor)
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
        .padding(.top, 8)
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

struct ActivityMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityMenuView(
            activity: FullFeedActivityDTO.mockDinnerActivity,
            showReportDialog: .constant(false)
        )
    }
} 

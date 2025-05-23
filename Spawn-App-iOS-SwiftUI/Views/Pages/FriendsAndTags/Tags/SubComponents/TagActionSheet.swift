//
//  TagActionSheet.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-11.
//

import SwiftUI

struct TagActionSheet: View {
    var tag: FullFriendTagDTO
    var onRenameTag: () -> Void
    var onChangeTagColor: () -> Void
    var onManageTaggedPeople: () -> Void
    var onDeleteTag: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Action buttons
            VStack(spacing: 0) {
                // Rename Tag
                Button(action: {
                    onRenameTag()
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .frame(width: 24)
                        Text("Rename Tag")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
					.foregroundColor(universalAccentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                // Change Tag Colour
                Button(action: {
                    onChangeTagColor()
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .frame(width: 24)
                        Text("Change Tag Colour")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
					.foregroundColor(universalAccentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                // Manage Tagged People
                Button(action: {
                    onManageTaggedPeople()
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .frame(width: 24)
                        Text("Manage Tagged People")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
					.foregroundColor(universalAccentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                // Delete Tag
                Button(action: {
                    onDeleteTag()
                    onDismiss()
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .frame(width: 24)
                            .foregroundColor(.red)
                        Text("Delete Tag")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Cancel button
            Button(action: {
                onDismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
        .background(Color.black.opacity(0.4))
        .edgesIgnoringSafeArea(.all)
    }
}

@available(iOS 17, *)
#Preview {
    TagActionSheet(
        tag: FullFriendTagDTO.close,
        onRenameTag: {},
        onChangeTagColor: {},
        onManageTaggedPeople: {},
        onDeleteTag: {},
        onDismiss: {}
    )
} 

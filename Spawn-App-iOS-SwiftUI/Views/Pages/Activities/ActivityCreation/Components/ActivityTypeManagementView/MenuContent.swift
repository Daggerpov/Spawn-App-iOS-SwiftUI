import SwiftUI

// Content view that contains the actual menu items for ActivityTypeFriendMenuView
struct MenuContent: View {
    let friend: BaseUserDTO
    let activityType: ActivityTypeDTO
    let navigateToProfile: () -> Void
    let removeFromType: () -> Void
    let dismiss: DismissAction
    
    private var firstName: String {
        if let name = friend.name, !name.isEmpty {
            return name.components(separatedBy: " ").first ?? friend.username ?? "User"
        }
        return friend.username ?? "User"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            menuItems
                .background(universalBackgroundColor)
            
            cancelButton
        }
        .background(universalBackgroundColor)
    }
    
    private var menuItems: some View {
        VStack(spacing: 0) {
            menuItem(
                icon: "person.crop.circle",
                text: "View Profile",
                color: universalAccentColor
            ) {
                dismiss()
                navigateToProfile()
            }
            .background(universalBackgroundColor)
            
            Divider()
            
            menuItem(
                icon: "person.badge.minus",
                text: "Remove from \(activityType.title)",
                color: .red
            ) {
                removeFromType()
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


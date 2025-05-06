import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var isShowingPermissionAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Notification Status")) {
                HStack {
                    Image(systemName: notificationService.isNotificationsEnabled ? "bell.fill" : "bell.slash.fill")
                        .foregroundColor(notificationService.isNotificationsEnabled ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notificationService.isNotificationsEnabled ? "Notifications Enabled" : "Notifications Disabled")
                            .font(.headline)
                        
                        Text(notificationService.isNotificationsEnabled 
                            ? "You will receive notifications from Spawn" 
                            : "Enable notifications in your device settings")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                }
                .padding(.vertical, 8)
                
                if !notificationService.isNotificationsEnabled {
                    Button("Enable Notifications") {
                        requestPermission()
                    }
                    .foregroundColor(universalAccentColor)
                }
            }
            
            if notificationService.isNotificationsEnabled {
                Section(header: Text("Notification Types")) {
                    if notificationService.isLoadingPreferences {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                    } else {
                        Toggle("Friend Requests", isOn: $notificationService.friendRequestsEnabled)
                            .onChange(of: notificationService.friendRequestsEnabled) { _ in
                                updatePreferences()
                            }
                        
                        Toggle("Event Invites", isOn: $notificationService.eventInvitesEnabled)
                            .onChange(of: notificationService.eventInvitesEnabled) { _ in
                                updatePreferences()
                            }
                        
                        Toggle("Event Updates", isOn: $notificationService.eventUpdatesEnabled)
                            .onChange(of: notificationService.eventUpdatesEnabled) { _ in
                                updatePreferences()
                            }
                        
                        Toggle("Chat Messages", isOn: $notificationService.chatMessagesEnabled)
                            .onChange(of: notificationService.chatMessagesEnabled) { _ in
                                updatePreferences()
                            }
                    }
                }
                
                #if DEBUG
                Section(header: Text("Test Notifications (Debug)")) {
                    Button("Test Friend Request Notification") {
                        NotificationService.shared.sendTestNotification(type: "friendRequest")
                    }
                    .disabled(!notificationService.friendRequestsEnabled)
                    
                    Button("Test Event Invite Notification") {
                        NotificationService.shared.sendTestNotification(type: "eventInvite")
                    }
                    .disabled(!notificationService.eventInvitesEnabled)
                    
                    Button("Test Event Update Notification") {
                        NotificationService.shared.sendTestNotification(type: "eventUpdate")
                    }
                    .disabled(!notificationService.eventUpdatesEnabled)
                    
                    Button("Test Chat Message Notification") {
                        NotificationService.shared.sendTestNotification(type: "chat")
                    }
                    .disabled(!notificationService.chatMessagesEnabled)
                }
                #endif
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            notificationService.checkNotificationStatus()
            Task {
                await notificationService.fetchNotificationPreferences()
            }
        }
        .refreshable {
            Task {
                await notificationService.fetchNotificationPreferences()
            }
        }
        .alert(isPresented: $isShowingPermissionAlert) {
            Alert(
                title: Text("Notification Permissions"),
                message: Text("Please enable notifications for Spawn in your device settings to receive updates about events and friends."),
                primaryButton: .default(Text("Open Settings"), action: {
                    openSettings()
                }),
                secondaryButton: .cancel()
            )
        }
        .background(Color.clear)
        .scrollContentBackground(.hidden)
        .background(universalBackgroundColor)
    }

    private func requestPermission() {
        Task {
            let granted = await notificationService.requestPermission()
            if !granted {
                isShowingPermissionAlert = true
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func updatePreferences() {
        Task {
            await notificationService.updateNotificationPreferences()
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    NavigationView {
        NotificationSettingsView()
    }.environmentObject(appCache)
} 

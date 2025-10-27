import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var isShowingPermissionAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Notifications")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                // Empty view for balance
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Content
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
                                .onChange(of: notificationService.friendRequestsEnabled) {
                                    updatePreferences()
                                }
                            
                            Toggle("Activity Invites", isOn: $notificationService.activityInvitesEnabled)
                                .onChange(of: notificationService.activityInvitesEnabled) {
                                    updatePreferences()
                                }
                            
                            Toggle("Activity Updates", isOn: $notificationService.activityUpdatesEnabled)
                                .onChange(of: notificationService.activityUpdatesEnabled) {
                                    updatePreferences()
                                }
                            
                            Toggle("Chat Messages", isOn: $notificationService.chatMessagesEnabled)
                                .onChange(of: notificationService.chatMessagesEnabled) {
                                    updatePreferences()
                                }
                        }
                    }
                    
                    Section(header: Text("Test Notifications")) {
                        Button("Test In-App Notification") {
                            testInAppNotification()
                        }
                        .foregroundColor(universalAccentColor)
                        
                        Button("Test Push Notification (Local)") {
                            testPushNotification()
                        }
                        .foregroundColor(universalAccentColor)
                    }
                }
            }
            .task {
                notificationService.checkNotificationStatus()
                await notificationService.fetchNotificationPreferences()
            }
            .refreshable {
                Task {
                    await notificationService.fetchNotificationPreferences()
                }
            }
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .alert(isPresented: $isShowingPermissionAlert) {
            Alert(
                title: Text("Notification Permissions"),
                message: Text("Please enable notifications for Spawn in your device settings to receive updates about activities and friends."),
                primaryButton: .default(Text("Open Settings"), action: {
                    openSettings()
                }),
                secondaryButton: .cancel()
            )
        }
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
    
    private func testInAppNotification() {
        // Test the in-app notification directly
        InAppNotificationManager.shared.showNotification(
            title: "Test Notification",
            message: "This is a test in-app notification to verify the fix works!",
            type: .success,
            duration: 5.0
        )
    }
    
    private func testPushNotification() {
        // Test by simulating a push notification payload
        let testPayload: [AnyHashable: Any] = [
            "type": "friend-request",
            "senderName": "Test User",
            "senderId": UUID().uuidString,
            "requestId": UUID().uuidString
        ]
        
        // Simulate what happens when a push notification is received while app is in foreground
        InAppNotificationManager.shared.showNotificationFromPushData(testPayload)
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @ObservedObject var appCache = AppCache.shared
    NavigationView {
        NotificationSettingsView()
    }.environmentObject(appCache)
} 

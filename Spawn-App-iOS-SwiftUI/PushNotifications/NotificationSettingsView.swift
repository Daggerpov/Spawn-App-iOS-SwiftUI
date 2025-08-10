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
                                .onChange(of: notificationService.friendRequestsEnabled) { _ in
                                    updatePreferences()
                                }
                            
                            Toggle("Activity Invites", isOn: $notificationService.activityInvitesEnabled)
                                .onChange(of: notificationService.activityInvitesEnabled) { _ in
                                    updatePreferences()
                                }
                            
                            Toggle("Activity Updates", isOn: $notificationService.activityUpdatesEnabled)
                                .onChange(of: notificationService.activityUpdatesEnabled) { _ in
                                    updatePreferences()
                                }
                            
                            Toggle("Chat Messages", isOn: $notificationService.chatMessagesEnabled)
                                .onChange(of: notificationService.chatMessagesEnabled) { _ in
                                    updatePreferences()
                                }
                        }
                    }
                                    }
            }
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
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    NavigationView {
        NotificationSettingsView()
    }.environmentObject(appCache)
} 

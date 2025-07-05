import SwiftUI

struct BlockedUsersView: View {
    @StateObject private var viewModel = BlockedUsersViewModel()
    @EnvironmentObject var userAuth: UserAuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showUnblockConfirmation = false
    @State private var userToUnblock: BlockedUserDTO?
    @State private var showNotification = false
    @State private var notificationMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading blocked users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.blockedUsers.isEmpty {
                    emptyStateView
                } else {
                    blockedUsersList
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: cancelButton)
            .onAppear {
                loadBlockedUsers()
            }
            .alert("Unblock User", isPresented: $showUnblockConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Unblock", role: .destructive) {
                    if let user = userToUnblock {
                        unblockUser(user)
                    }
                }
            } message: {
                if let user = userToUnblock {
                    Text("Are you sure you want to unblock \(user.blockedUsername)?")
                }
            }
            .overlay(
                notificationToast,
                alignment: .top
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var cancelButton: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Blocked Users")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Users you block will appear here. You can unblock them at any time.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var blockedUsersList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.blockedUsers, id: \.id) { blockedUser in
                    BlockedUserRow(
                        blockedUser: blockedUser,
                        onUnblock: {
                            userToUnblock = blockedUser
                            showUnblockConfirmation = true
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .refreshable {
            await loadBlockedUsersAsync()
        }
    }
    
    private var notificationToast: some View {
        Group {
            if showNotification {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(notificationMessage)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()
                .transition(.move(edge: .top))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showNotification = false
                        }
                    }
                }
            }
        }
    }
    
    private func loadBlockedUsers() {
        Task {
            await loadBlockedUsersAsync()
        }
    }
    
    private func loadBlockedUsersAsync() async {
        guard let currentUserId = userAuth.spawnUser?.id else { return }
        await viewModel.loadBlockedUsers(for: currentUserId)
    }
    
    private func unblockUser(_ blockedUser: BlockedUserDTO) {
        guard let currentUserId = userAuth.spawnUser?.id else { return }
        
        Task {
            await viewModel.unblockUser(
                blockerId: currentUserId,
                blockedId: blockedUser.blockedId
            )
            
            await MainActor.run {
                notificationMessage = "\(blockedUser.blockedUsername) has been unblocked"
                withAnimation {
                    showNotification = true
                }
            }
        }
    }
}

struct BlockedUserRow: View {
    let blockedUser: BlockedUserDTO
    let onUnblock: () -> Void
    
    var body: some View {
        HStack {
            // User Avatar (placeholder)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(blockedUser.blockedUsername.prefix(1).uppercased()))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(blockedUser.blockedUsername)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !blockedUser.reason.isEmpty {
                    Text("Reason: \(blockedUser.reason)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button("Unblock") {
                onUnblock()
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    BlockedUsersView()
        .environmentObject(UserAuthViewModel.shared)
} 
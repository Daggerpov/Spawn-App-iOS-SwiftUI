import SwiftUI

struct ActivityTypeManagementView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @State private var showingOptions = false
    @State private var showingManagePeople = false
    
    // Use the ActivityTypeViewModel for managing activity types
    @StateObject private var viewModel: ActivityTypeViewModel
    
    init(activityTypeDTO: ActivityTypeDTO) {
        self.activityTypeDTO = activityTypeDTO
        
        // Initialize the view model with userId
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(universalAccentColor)
                }
                
                Spacer()
                
                Text("Manage Type - \(activityTypeDTO.title)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                Button(action: { showingOptions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(universalAccentColor)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(universalBackgroundColor)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Activity Type Card
                    activityTypeCard
                    
                    // People Section
                    peopleSection
                }
                .padding()
            }
            .background(universalBackgroundColor)
            
            // Loading overlay
            if viewModel.isLoading {
                ProgressView("Deleting...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingManagePeople) {
            ManagePeopleView(activityTypeDTO: activityTypeDTO)
        }
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text("Options"),
                buttons: [
                    .default(Text("Manage People")) {
                        showingManagePeople = true
                    },
                    .destructive(Text("Delete Activity Type")) {
                        viewModel.deleteActivityType(activityTypeDTO)
                        // Dismiss the view after successful deletion
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    },
                    .cancel()
                ]
            )
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var activityTypeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 120)
            
            VStack(spacing: 8) {
                Text(activityTypeDTO.icon)
                    .font(.system(size: 48))
                
                Text(activityTypeDTO.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(universalAccentColor)
            }
            
            // Edit button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        // Handle edit action
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .background(universalBackgroundColor)
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(16)
        }
        .padding(.horizontal)
    }
    
    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if activityTypeDTO.associatedFriends.isEmpty {
                // Empty state
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)
                    
                    VStack(spacing: 16) {
                        Text("No people yet!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(universalAccentColor)
                        
                        Text("You haven't added placed friends under this tag yet. Tap below to get started!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Button(action: { showingManagePeople = true }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add friends")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(.green)
                        )
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // People exist - show the list
                HStack {
                    Text("People (\(activityTypeDTO.associatedFriends.count))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    Button(action: { showingManagePeople = true }) {
                        Text("Manage People")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // People List
                LazyVStack(spacing: 12) {
                    ForEach(activityTypeDTO.associatedFriends, id: \.id) { friend in
                        PersonRowView(friend: friend, activityTypeDTO: activityTypeDTO)
                    }
                }
            }
        }
    }
}

struct PersonRowView: View {
    let friend: BaseUserDTO
    let activityTypeDTO: ActivityTypeDTO
    @State private var showingPersonOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: friend.profilePicture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Name and Username
            VStack(alignment: .leading, spacing: 2) {
				Text(FormatterService.shared.formatName(user: friend))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(universalAccentColor)
                
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Options Button
            Button(action: { showingPersonOptions = true }) {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .actionSheet(isPresented: $showingPersonOptions) {
            ActionSheet(
				title: Text(FormatterService.shared.formatName(user: friend)),
                buttons: [
                    .default(Text("View Profile")) {
                        // Handle view profile
                    },
                    .default(Text("Send Message")) {
                        // Handle send message
                    },
                    .destructive(Text("Remove from Type")) {
                        // Handle remove from type
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct ManagePeopleView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Manage People for \(activityTypeDTO.title)")
                    .font(.title2)
                    .padding()
                
                // Add your manage people implementation here
                
                Spacer()
            }
            .navigationTitle("Manage People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityTypeManagementView(activityTypeDTO: ActivityTypeDTO.mockChillActivityType)
        .environmentObject(appCache)
} 

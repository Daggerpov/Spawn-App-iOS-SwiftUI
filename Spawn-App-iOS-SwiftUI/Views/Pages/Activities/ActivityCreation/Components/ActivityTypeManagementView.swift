import SwiftUI

struct ActivityTypeManagementView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
    
    // Adaptive background color for activity type card
    private var adaptiveCardBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.08)
        case .light:
            return Color.gray.opacity(0.1)
        @unknown default:
            return Color.gray.opacity(0.1)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - matching Figma design
            HStack(spacing: 32) {
                Button(action: { dismiss() }) {
                    Text("􀆉")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Manage Type - \(activityTypeDTO.title)")
                    .font(.onestSemiBold(size: 20))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingOptions = true }) {
                    Text("􀍠")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(universalBackgroundColor)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Activity Type Card - matching Figma design  
                    activityTypeCard
                    
                    // People Section - matching Figma design
                    peopleSection
                }
                .padding(.horizontal, 26)
                .padding(.top, 24)
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
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 0.24, green: 0.23, blue: 0.23))
                .frame(width: 145, height: 145)
            
            VStack(spacing: 15) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                    
                    Text(activityTypeDTO.icon)
                        .font(.system(size: 24))
                }
                .frame(width: 40, height: 40)
                
                // Activity Title
                Text(activityTypeDTO.title)
                    .font(.onestMedium(size: 24))
                    .foregroundColor(.white)
            }
            .padding(20)
            
            // Edit button overlay - positioned at top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        // Handle edit action
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.52, green: 0.49, blue: 0.49))
                                .frame(width: 36.25, height: 36.25)
                            
                            Text("􀈊")
                                .font(.system(size: 21.75))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 10, y: -10)
                }
                Spacer()
            }
        }
        .frame(width: 145, height: 145)
    }
    
    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                // People exist - show the list with Figma styling
                HStack(alignment: .bottom, spacing: 12) {
                    Text("People (\(activityTypeDTO.associatedFriends.count))")
                        .font(.onestSemiBold(size: 17))
                        .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                    
                    Spacer()
                    
                    Button(action: { showingManagePeople = true }) {
                        Text("Manage People")
                            .font(.onestMedium(size: 16))
                            .foregroundColor(Color(red: 0.33, green: 0.42, blue: 0.93))
                    }
                }
                
                // People List - matching Figma design
                VStack(spacing: 12) {
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
            // Profile Image - matching Figma design
            AsyncImage(url: URL(string: friend.profilePicture ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.25), radius: 4.06, y: 1.62)
            
            // Name and Username - matching Figma design
            VStack(alignment: .leading, spacing: 0) {
				Text(FormatterService.shared.formatName(user: friend))
                    .font(.onestSemiBold(size: 14))
                    .foregroundColor(.white)
                
                Text("@\(friend.username)")
                    .font(.onestSemiBold(size: 14))
                    .foregroundColor(.white)
            }
            .lineSpacing(22.40)
            
            Spacer()
            
            // Options Button - matching Figma design
            Button(action: { showingPersonOptions = true }) {
                Text("􀍠")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
            }
        }
        .cornerRadius(12)
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

import SwiftUI

struct ActivityTypeManagementView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingOptions = false
    @State private var showingManagePeople = false
    @State private var showingEditView = false
    
    // Use the ActivityTypeViewModel for managing activity types
    @StateObject private var viewModel: ActivityTypeViewModel
    
    init(activityTypeDTO: ActivityTypeDTO) {
        self.activityTypeDTO = activityTypeDTO
        
        // Initialize the view model with userId
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header - following app's standard pattern
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(universalAccentColor)
                    }
                    
                    Spacer()
                    
                    Text("Manage Type - \(activityTypeDTO.title)")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    Button(action: { showingOptions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(universalAccentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Activity Type Card
                        activityTypeCard
                        
                        // People Section
                        peopleSection
                    }
                    .padding(.horizontal, 24)
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
                .environmentObject(AppCache.shared)
        }
        .fullScreenCover(isPresented: $showingEditView) {
            ActivityTypeEditView(activityTypeDTO: activityTypeDTO)
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
            
            // Custom popup overlay
            if showingOptions {
                ActivityTypeOptionsPopup(
                    isPresented: $showingOptions,
                    onManagePeople: {
                        showingManagePeople = true
                    },
                    onDeleteActivityType: {
                        viewModel.deleteActivityType(activityTypeDTO)
                        // Dismiss the view after successful deletion
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                )
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
                        showingEditView = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.52, green: 0.49, blue: 0.49))
                                .frame(width: 36.25, height: 36.25)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
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
            // Header with people count and manage button
            HStack(alignment: .bottom, spacing: 12) {
                Text("People (\(activityTypeDTO.associatedFriends.count))")
                    .font(.onestSemiBold(size: 17))
                    .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                
                Button(action: { showingManagePeople = true }) {
                    Text("Manage People")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalAccentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
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
                        
                        Text("You haven't added placed friends under this tag yet. Tap 'Manage People' above to get started!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                        .frame(height: 60)
                }
            } else {
                // People list - following Figma design pattern
                LazyVStack(spacing: 12) {
                    ForEach(activityTypeDTO.associatedFriends, id: \.id) { friend in
                        peopleRowView(friend: friend)
                    }
                }
            }
        }
    }
    
    private func peopleRowView(friend: BaseUserDTO) -> some View {
        PeopleRowView(friend: friend)
    }
}

struct PeopleRowView: View {
    let friend: BaseUserDTO
    @State private var showingPersonOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Profile picture
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
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                
                // Name and username
                VStack(alignment: .leading, spacing: 2) {
                    Text(FormatterService.shared.formatName(user: friend))
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                    
                    Text("@\(friend.username ?? "")")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Menu button
            Button(action: {
                showingPersonOptions = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
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

struct ActivityTypeOptionsPopup: View {
    @Binding var isPresented: Bool
    let onManagePeople: () -> Void
    let onDeleteActivityType: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveOverlayColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.4)
    }
    
    private var adaptivePopupBackground: Color {
        colorScheme == .dark ? Color(red: 0.24, green: 0.23, blue: 0.23) : Color(red: 0.95, green: 0.95, blue: 0.95)
    }
    
    private var adaptiveBorderColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : Color(red: 0.85, green: 0.85, blue: 0.85)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            adaptiveOverlayColor
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Popup content positioned at bottom
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Main options group
                    VStack(alignment: .leading, spacing: 0) {
                        // Manage People option
                        Button(action: {
                            onManagePeople()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            HStack(spacing: 10) {
                                Text("Manage People")
                                    .font(.onestMedium(size: 20))
                                    .foregroundColor(universalAccentColor)
                                Spacer()
                            }
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .frame(height: 63)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(adaptivePopupBackground)
                            .overlay(
                                Rectangle()
                                    .inset(by: 0.50)
                                    .stroke(adaptiveBorderColor, lineWidth: 0.50)
                            )
                            .shadow(
                                color: Color.black.opacity(0.1), radius: 8, y: 2
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete Activity Type option
                        Button(action: {
                            onDeleteActivityType()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            HStack(spacing: 10) {
                                Text("􀈑")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(universalTertiaryColor)
                                Text("Delete Activity Type")
                                    .font(.onestMedium(size: 20))
                                    .foregroundColor(universalTertiaryColor)
                                Spacer()
                            }
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .frame(height: 63)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(adaptivePopupBackground)
                            .shadow(
                                color: Color.black.opacity(0.1), radius: 8, y: 2
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .cornerRadius(16)
                    
                    // Cancel button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 10) {
                            Text("􀆄")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(universalAccentColor)
                            Text("Cancel")
                                .font(.onestMedium(size: 20))
                                .foregroundColor(universalAccentColor)
                            Spacer()
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .frame(height: 63)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(adaptivePopupBackground)
                        .cornerRadius(16)
                        .shadow(
                            color: Color.black.opacity(0.1), radius: 8, y: 2
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 380)
                .padding(.bottom, 50) // Add bottom padding for safe area
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

struct ManagePeopleView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appCache: AppCache
    
    @State private var searchText = ""
    @State private var selectedFriends: Set<UUID> = []
    @State private var showingAddedPeople = false
    @State private var isLoading = false
    
    @StateObject private var viewModel: ActivityTypeViewModel
    
    // Initialize selected friends with existing associated friends
    init(activityTypeDTO: ActivityTypeDTO) {
        self.activityTypeDTO = activityTypeDTO
        _selectedFriends = State(initialValue: Set(activityTypeDTO.associatedFriends.map { $0.id }))
        
        // Initialize the view model with userId
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if activityTypeDTO.associatedFriends.isEmpty {
                    emptyStateView
                } else {
                    populatedStateView
                }
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Saving changes...")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
            }
        }
        .onAppear {
            // Initialize selected friends when view appears
            selectedFriends = Set(activityTypeDTO.associatedFriends.map { $0.id })
        }
        .onDisappear {
            // Save changes when view disappears
            Task {
                await saveChanges()
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 32) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Manage People - \(activityTypeDTO.title)")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                Task {
                    await saveChanges()
                    dismiss()
                }
            }) {
                Text("Save")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(figmaBlue)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Instructions text
            Text("Select friends to add to this type")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Search bar
            searchBarView
            
            // Friends list for empty state
            emptyStateFriendsListView
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var populatedStateView: some View {
        VStack(spacing: 24) {
            // Search bar
            searchBarView
            
            // Suggested friends section
            if !suggestedFriends.isEmpty {
                suggestedFriendsSection
            }
            
            // Added friends section
            if !addedFriends.isEmpty {
                addedFriendsSection
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(figmaBlack300)
            
            TextField("Search by name or handle...", text: $searchText)
                .font(.onestMedium(size: 16))
                .foregroundColor(figmaBlack300)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(figmaBlack300, lineWidth: 0.5)
        )
    }
    
    private var emptyStateFriendsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(alignment: .bottom, spacing: 12) {
                Text("Your Friends (\(availableFriends.count))")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(figmaBlack300)
                
                Spacer()
                
                Button(action: {
                    if selectedFriends.count == availableFriends.count {
                        selectedFriends.removeAll()
                    } else {
                        selectedFriends = Set(availableFriends.map { $0.id })
                    }
                }) {
                    Text(selectedFriends.count == availableFriends.count ? "Deselect All" : "Select All")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(figmaBlue)
                }
            }
            
            // Friends list with selection circles
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredFriends, id: \.id) { friend in
                        FriendSelectionRow(
                            friend: friend,
                            isSelected: selectedFriends.contains(friend.id),
                            onToggle: {
                                if selectedFriends.contains(friend.id) {
                                    selectedFriends.remove(friend.id)
                                } else {
                                    selectedFriends.insert(friend.id)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var suggestedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                Text("Suggested")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(figmaBlack300)
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            // Show suggested friends (friends not yet added)
            LazyVStack(spacing: 12) {
                ForEach(suggestedFriends.prefix(3), id: \.id) { friend in
                    SuggestedFriendRow(
                        friend: friend,
                        onAdd: {
                            selectedFriends.insert(friend.id)
                        }
                    )
                }
            }
        }
    }
    
    private var addedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("Added (\(addedFriends.count))")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(figmaBlack300)
                
                Spacer()
                
                Button(action: {
                    selectedFriends.removeAll()
                }) {
                    Text("Clear Selection")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(figmaBlue)
                }
            }
            
            // Show added friends
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(addedFriends, id: \.id) { friend in
                        AddedFriendRow(
                            friend: friend,
                            onRemove: {
                                selectedFriends.remove(friend.id)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableFriends: [FullFriendUserDTO] {
        appCache.friends
    }
    
    private var filteredFriends: [FullFriendUserDTO] {
        if searchText.isEmpty {
            return availableFriends
        }
        
        return availableFriends.filter { friend in
            let name = friend.name?.lowercased() ?? ""
            let username = friend.username.lowercased()
            let search = searchText.lowercased()
            
            return name.contains(search) || username.contains(search)
        }
    }
    
    private var suggestedFriends: [FullFriendUserDTO] {
        return availableFriends.filter { friend in
            !selectedFriends.contains(friend.id)
        }
    }
    
    private var addedFriends: [FullFriendUserDTO] {
        return availableFriends.filter { friend in
            selectedFriends.contains(friend.id)
        }
    }
    
    // MARK: - Methods
    
    private func saveChanges() async {
        // Check if there are any changes to save
        let currentFriendIds = Set(activityTypeDTO.associatedFriends.map { $0.id })
        let hasChanges = currentFriendIds != selectedFriends
        
        guard hasChanges else {
            return // No changes to save
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        // Convert selected friend IDs to BaseUserDTO objects
        let selectedFriendObjects = appCache.friends.compactMap { friend in
            if selectedFriends.contains(friend.id) {
                return BaseUserDTO.from(friendUser: friend)
            }
            return nil
        }
        
        // Create updated activity type with new associated friends
        let updatedActivityType = ActivityTypeDTO(
            id: activityTypeDTO.id,
            title: activityTypeDTO.title,
            icon: activityTypeDTO.icon,
            associatedFriends: selectedFriendObjects,
            orderNum: activityTypeDTO.orderNum,
            isPinned: activityTypeDTO.isPinned
        )
        
        // Update the activity type using the view model
        await MainActor.run {
            viewModel.updateActivityType(updatedActivityType)
        }
        
        // Save the changes to the backend
        await viewModel.saveBatchChanges()
        
        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Friend Row Views

struct FriendSelectionRow: View {
    let friend: FullFriendUserDTO
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Profile picture
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
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                
                // Name and username
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name ?? "")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                    
                    Text("@\(friend.username)")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Selection indicator
            Button(action: onToggle) {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 27, height: 27)
                    .overlay(
                        Circle()
                            .stroke(figmaBlack300, lineWidth: 1)
                            .overlay(
                                Circle()
                                    .fill(isSelected ? figmaBlue : Color.clear)
                                    .frame(width: 17, height: 17)
                            )
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
    }
}

struct SuggestedFriendRow: View {
    let friend: FullFriendUserDTO
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Profile picture
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
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                
                // Name and username
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name ?? "")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                    
                    Text("@\(friend.username)")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Add button
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(figmaBlack300)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
    }
}

struct AddedFriendRow: View {
    let friend: FullFriendUserDTO
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Profile picture
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
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                
                // Name and username
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.name ?? "")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                    
                    Text("@\(friend.username)")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Remove button (checkmark)
            Button(action: onRemove) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24))
                    .foregroundColor(figmaGreen)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityTypeManagementView(activityTypeDTO: ActivityTypeDTO.mockChillActivityType)
        .environmentObject(appCache)
} 

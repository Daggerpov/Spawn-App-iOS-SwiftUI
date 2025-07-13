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
    
    // Computed property to get the current activity type data from view model
    private var currentActivityType: ActivityTypeDTO? {
        return viewModel.activityTypes.first { $0.id == activityTypeDTO.id }
    }
    
    // Use current data if available, otherwise fall back to original
    private var displayActivityType: ActivityTypeDTO {
        return currentActivityType ?? activityTypeDTO
    }
    
    // MARK: - Theme-aware colors
    private var adaptiveCardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.24, green: 0.23, blue: 0.23) : Color(red: 0.95, green: 0.93, blue: 0.93)
    }
    
    private var adaptiveEditButtonColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : Color(red: 0.75, green: 0.75, blue: 0.75)
    }
    
    private var adaptiveCardTextColor: Color {
        colorScheme == .dark ? Color.white : universalAccentColor
    }
    
    private var adaptivePeopleCountColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : figmaBlack300
    }
    
    private var adaptiveEmptyStateTextColor: Color {
        colorScheme == .dark ? Color.white : universalAccentColor
    }
    
    private var adaptiveEmptyStateDescriptionColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : figmaBlack300
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
                    
                    Text("Manage Type - \(displayActivityType.title)")
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
                    .navigationDestination(isPresented: $showingManagePeople) {
            ManagePeopleView(
                user: UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov,
                activityTitle: displayActivityType.title,
                activityTypeDTO: displayActivityType
            )
        }
        .onAppear {
            // Fetch the latest activity types when the view appears
            Task {
                await viewModel.fetchActivityTypes()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .activityTypesChanged)) { _ in
            // Refresh when activity types change
            Task {
                await viewModel.fetchActivityTypes()
            }
        }
        .fullScreenCover(isPresented: $showingEditView) {
            ActivityTypeEditView(activityTypeDTO: displayActivityType) {
                showingEditView = false
            }
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
                        Task {
                            await viewModel.deleteActivityType(displayActivityType)
                            // Dismiss the view after successful deletion
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var activityTypeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(adaptiveCardBackgroundColor)
                .frame(width: 145, height: 145)
            
            VStack(spacing: 15) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                    
                    Text(displayActivityType.icon)
                        .font(.system(size: 24))
                }
                .frame(width: 40, height: 40)
                
                // Activity Title
                Text(displayActivityType.title)
                    .font(.onestMedium(size: 24))
                    .foregroundColor(adaptiveCardTextColor)
            }
            .padding(20)
            
            // Edit button overlay - positioned at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingEditView = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(adaptiveEditButtonColor)
                                .frame(width: 36.25, height: 36.25)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 10, y: 10)
                }
            }
        }
        .frame(width: 145, height: 145)
    }
    
    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Only show header when there are friends
            if !displayActivityType.associatedFriends.isEmpty {
                // Header with people count and manage button - improved alignment
                HStack(alignment: .center, spacing: 12) {
                    Text("People (\(displayActivityType.associatedFriends.count))")
                        .font(.onestSemiBold(size: 17))
                        .foregroundColor(adaptivePeopleCountColor)
                    
                    Spacer()
                    
                    Button(action: { showingManagePeople = true }) {
                        Text("Manage People")
                            .font(.onestMedium(size: 16))
                            .foregroundColor(figmaBlue)
                    }
                }
            }
            
            if displayActivityType.associatedFriends.isEmpty {
                // Empty state - new design
                emptyStateView
            } else {
                // People list - following Figma design pattern
                LazyVStack(spacing: 12) {
                    ForEach(displayActivityType.associatedFriends, id: \.id) { friend in
                        peopleRowView(friend: friend)
                    }
                }
            }
        }
    }
    
    private func peopleRowView(friend: BaseUserDTO) -> some View {
        PeopleRowView(friend: friend)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // No people yet text
            Text("No people yet!")
                .font(.onestSemiBold(size: 28))
                .foregroundColor(adaptiveEmptyStateTextColor)
            
            Spacer()
                .frame(height: 24)
            
            // Description text
            Text("You haven't added placed friends under this tag yet. Tap below to get started!")
                .font(.onestMedium(size: 16))
                .foregroundColor(adaptiveEmptyStateDescriptionColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineLimit(nil)
            
            Spacer()
                .frame(height: 32)
            
            // Add friends button - matching Figma design exactly
            Button(action: { showingManagePeople = true }) {
                HStack(spacing: 5.6) {
                    Image(systemName: "plus")
                        .font(.system(size: 16.8, weight: .semibold))
                        .foregroundColor(figmaGreen)
                    
                    Text("Add friends")
                        .font(.onestSemiBold(size: 16.8))
                        .foregroundColor(figmaGreen)
                }
                .padding(EdgeInsets(top: 16.8, leading: 22.4, bottom: 16.8, trailing: 22.4))
                .frame(height: 55.35)
                .background(
                    RoundedRectangle(cornerRadius: 115.5)
                        .stroke(figmaGreen, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct PeopleRowView: View {
    let friend: BaseUserDTO
    @State private var showingPersonOptions = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Theme-aware colors
    private var adaptiveNameColor: Color {
        colorScheme == .dark ? Color.white : universalAccentColor
    }
    
    private var adaptiveMenuButtonColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : figmaBlack300
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                // Profile picture
                AsyncImage(url: friend.profilePicture.flatMap { URL(string: $0) }) { image in
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
                        .foregroundColor(adaptiveNameColor)
                    
                    Text("@\(friend.username)")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(adaptiveNameColor)
                }
            }
            
            Spacer()
            
            // Menu button
            Button(action: {
                showingPersonOptions = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(adaptiveMenuButtonColor)
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
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay - matching Figma exactly
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.60))
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
                                    .font(Font.custom("Onest", size: 20).weight(.medium))
                                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                            }
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .frame(height: 63)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color(red: 0.95, green: 0.93, blue: 0.93))
                            .overlay(
                                Rectangle()
                                    .inset(by: 0.50)
                                    .stroke(Color(red: 0.52, green: 0.49, blue: 0.49), lineWidth: 0.50)
                            )
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete Activity Type option
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "trash")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.red)
                                Text("Delete Activity Type")
                                    .font(Font.custom("Onest", size: 20).weight(.medium))
                                    .foregroundColor(.red)
                            }
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .frame(height: 63)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color(red: 0.95, green: 0.93, blue: 0.93))
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
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
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                            Text("Cancel")
                                .font(Font.custom("Onest", size: 20).weight(.medium))
                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .frame(height: 63)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(red: 0.95, green: 0.93, blue: 0.93))
                        .cornerRadius(16)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 380)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert("Delete Activity Type", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDeleteActivityType()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
        } message: {
            Text("Are you sure you want to delete this activity type? This action cannot be undone.")
        }
    }
}

// MARK: - ManagePeopleView and Related Components
// The ManagePeopleView is now implemented as a standalone full-page view in:
// Views/Pages/Activities/ManagePeopleView.swift
// This allows for better navigation and follows the Figma design as a full page instead of a sheet.

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityTypeManagementView(activityTypeDTO: ActivityTypeDTO.mockChillActivityType)
        .environmentObject(appCache)
} 

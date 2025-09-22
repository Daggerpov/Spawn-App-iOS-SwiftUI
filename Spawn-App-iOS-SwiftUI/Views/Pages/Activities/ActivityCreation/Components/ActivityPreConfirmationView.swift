import SwiftUI

struct ActivityPreConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    let onCreateActivity: () -> Void
    let onBack: (() -> Void)?
    
    // MARK: - Adaptive Colors
    private var adaptiveBackgroundColor: Color {
        universalBackgroundColor(from: themeService, environment: colorScheme)
    }
    
    private var adaptiveTextColor: Color {
        universalAccentColor(from: themeService, environment: colorScheme)
    }
    
    private var adaptiveSecondaryTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.56, green: 0.52, blue: 0.52)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    private var adaptiveCardBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.24, green: 0.23, blue: 0.23)
        case .light:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        @unknown default:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        }
    }
    
    private var adaptiveLoadingTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.56, green: 0.52, blue: 0.52)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and title
            headerView
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Activity card
                activityCardView
                    .padding(.horizontal, 24)
                
                // Activity title
                Text(viewModel.activity.title?.isEmpty == false ? viewModel.activity.title! : (viewModel.selectedActivityType?.title ?? "Morning Stroll"))
                    .font(.onestSemiBold(size: 32))
                    .foregroundColor(adaptiveTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                // Location and time
                HStack(spacing: 4) {
                    if let location = viewModel.selectedLocation {
                        Text(location.name)
                    } else {
                        Text("Location TBD")
                    }
                    
                    Text("@")
                    
                    Text(formatTime(viewModel.selectedDate))
                }
                .font(.onestMedium(size: 20))
                .foregroundColor(adaptiveSecondaryTextColor)
                .padding(.top, 12)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Step indicators
                StepIndicatorView(currentStep: 3, totalSteps: 3)
                    .padding(.bottom, 16)
                
                // Create/Update Activity button
                ActivityNextStepButton(
                    title: viewModel.isCreatingActivity ? (viewModel.isEditingExistingActivity ? "Updating..." : "Creating...") : (viewModel.isEditingExistingActivity ? "Update Activity" : "Looks good to me!"),
                    isEnabled: !viewModel.isCreatingActivity
                ) {
                    Task {
                        if viewModel.isEditingExistingActivity {
                            await viewModel.updateActivity()
                        } else {
                            await viewModel.createActivity()
                        }
                        await MainActor.run {
                            onCreateActivity()
                        }
                    }
                }
                
                // Loading indicator
                if viewModel.isCreatingActivity {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: adaptiveTextColor))
                            .scaleEffect(0.8)
                        
                        Text("Creating your activity...")
                            .font(.onestMedium(size: 14))
                            .foregroundColor(adaptiveLoadingTextColor)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .padding(.bottom, 80) // Standard bottom padding
        .background(adaptiveBackgroundColor)
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            if let onBack = onBack {
                ActivityBackButton {
                    onBack()
                }
                .padding(.leading, 24)
            }
            
            Spacer()
            
            // Title
            Text("Confirm")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(adaptiveTextColor)
            
            Spacer()
            
            // Invisible spacer for balance
            if onBack != nil {
                Color.clear
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 24)
            }
        }
        .padding(.top, 50)
        .padding(.bottom, 12)
    }
    
    // MARK: - Activity Card View
    private var activityCardView: some View {
        VStack(spacing: 18) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(adaptiveCardBackgroundColor)
                    .frame(width: 48, height: 48)
                
                Text(activityIcon)
                    .font(.system(size: 32))
            }
            
            // Activity details
            VStack(spacing: 12) {
                Text(viewModel.activity.title?.isEmpty == false ? viewModel.activity.title! : (viewModel.selectedActivityType?.title ?? "Morning Stroll"))
                    .font(.onestMedium(size: 24))
                    .foregroundColor(adaptiveTextColor)
                
                Text("\(viewModel.selectedActivityType?.associatedFriends.count ?? 0) people")
                    .font(.onestRegular(size: 18))
                    .foregroundColor(adaptiveSecondaryTextColor)
            }
        }
        .padding(24)
        .frame(width: 150, height: 150)
        .background(adaptiveCardBackgroundColor)
        .cornerRadius(18)
    }
    
    // MARK: - Computed Properties
    
    /// Returns the appropriate icon for the activity, prioritizing the activity's own icon over the activity type icon
    private var activityIcon: String {
        // For editing existing activities, use the activity's own icon if available and not the default star
        if let activityIcon = viewModel.activity.icon, !activityIcon.isEmpty && activityIcon != "⭐️" {
            return activityIcon
        }
        
        // For new activities, prioritize the selected activity type's icon
        if let activityTypeIcon = viewModel.selectedActivityType?.icon, !activityTypeIcon.isEmpty {
            return activityTypeIcon
        }
        
        // Final fallback to default star emoji (should rarely be reached)
        return "⭐️"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).uppercased()
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityPreConfirmationView(
        onCreateActivity: {
            print("Create activity tapped")
        },
        onBack: {
            print("Back tapped")
        }
    )
    .environmentObject(appCache)
} 

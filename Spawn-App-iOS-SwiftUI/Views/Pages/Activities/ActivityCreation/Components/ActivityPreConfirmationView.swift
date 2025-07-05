import SwiftUI

struct ActivityPreConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    let onCreateActivity: () -> Void
    let onBack: (() -> Void)?
    
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
                Text(viewModel.activity.title?.isEmpty == false ? viewModel.activity.title! : (viewModel.selectedType?.rawValue ?? "Morning Stroll"))
                    .font(.onestSemiBold(size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                // Location and time
                HStack(spacing: 4) {
                    if let location = viewModel.selectedLocation {
                        Text(location.name)
                    } else {
                        Text("Pacific Spirit Park")
                    }
                    
                    Text("@")
                    
                    Text(formatTime(viewModel.selectedDate))
                }
                .font(.onestMedium(size: 20))
                .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                .padding(.top, 12)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Step indicators
                StepIndicatorView(currentStep: 3, totalSteps: 3)
                    .padding(.bottom, 16)
                
                // Create Activity button
                ActivityNextStepButton(
                    title: viewModel.isCreatingActivity ? "Creating..." : "Looks good to me!",
                    isEnabled: !viewModel.isCreatingActivity
                ) {
                    Task {
                        await viewModel.createActivity()
                        await MainActor.run {
                            onCreateActivity()
                        }
                    }
                }
                
                // Loading indicator
                if viewModel.isCreatingActivity {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Creating your activity...")
                            .font(.onestMedium(size: 14))
                            .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                    }
                    .padding(.top, 16)
                }
            }
        }
        .padding(.bottom, 80)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 24)
            }
            
            Spacer()
            
            // Title
            Text("Confirm")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer for balance
            if onBack != nil {
                Color.clear
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 24)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
    
    // MARK: - Activity Card View
    private var activityCardView: some View {
        VStack(spacing: 18) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.24, green: 0.23, blue: 0.23))
                    .frame(width: 48, height: 48)
                
                Text(viewModel.selectedType?.icon ?? "🥾")
                    .font(.system(size: 32))
            }
            
            // Activity details
            VStack(spacing: 12) {
                Text(viewModel.selectedType?.rawValue ?? "Hike")
                    .font(.onestMedium(size: 24))
                    .foregroundColor(.white)
                
                Text("\(viewModel.selectedType?.peopleCount ?? 14) people")
                    .font(.onestRegular(size: 18))
                    .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
            }
        }
        .padding(24)
        .frame(width: 150, height: 150)
        .background(Color(red: 0.24, green: 0.23, blue: 0.23))
        .cornerRadius(18)
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
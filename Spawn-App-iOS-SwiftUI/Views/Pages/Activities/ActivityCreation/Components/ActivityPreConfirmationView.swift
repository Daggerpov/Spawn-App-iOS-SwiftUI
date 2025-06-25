import SwiftUI

struct ActivityPreConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    let onCreateActivity: () -> Void
    let onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            // Back button at the top (if provided)
            if let onBack = onBack {
                HStack {
                    ActivityBackButton {
                        onBack()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            Spacer()
            
            // Activity card
            VStack(spacing: 16) {
                // Activity icon and details
                VStack(spacing: 12) {
                    // Icon in gray background circle
                    Circle()
                        .fill(figmaLightGrey)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(viewModel.selectedType?.icon ?? "⭐️")
                                .font(.system(size: 32))
                        }
                    
                    // Activity type and people count
                    VStack(spacing: 4) {
                        Text(viewModel.selectedType?.rawValue ?? "General")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(universalAccentColor)
                        
                        Text("\(viewModel.selectedType?.peopleCount ?? 14) people")
                            .font(.subheadline)
                            .foregroundColor(figmaBlack300)
                    }
                }
                
                Spacer().frame(height: 20)
                
                // Activity title and location
                VStack(spacing: 8) {
                    Text(viewModel.activity.title?.isEmpty == false ? viewModel.activity.title! : (viewModel.selectedType?.rawValue ?? "Morning Stroll"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(universalAccentColor)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        if let location = viewModel.selectedLocation {
                            Text(location.name)
                        } else {
                            Text("Pacific Spirit Park")
                        }
                        
                        Text("@")
                        
                        Text(formatTime(viewModel.selectedDate))
                    }
                    .font(.subheadline)
                    .foregroundColor(figmaBlack300)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(figmaGrey)
            )
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Create Activity button
            ActivityNextStepButton(
                title: "Create Activity"
            ) {
                Task {
                    await viewModel.createActivity()
                    await MainActor.run {
                        onCreateActivity()
                    }
                }
            }
        }
        .background(universalBackgroundColor)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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
import SwiftUI

struct ActivityConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @Binding var showShareSheet: Bool
    let onClose: () -> Void
    let onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and title
            if onBack != nil {
                headerView
            }
            
            // Main content
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.green)
                
                Text("Success!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(universalAccentColor)
                
                Text("You've spawned in and \"\(activityTitle)\" is now live for your friends.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(figmaBlack300)
                    .padding(.horizontal, 24)
                
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share with your network")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                Button(action: onClose) {
                    Text("Return to Home")
                        .font(.headline)
                        .foregroundColor(universalAccentColor)
                }
                
                Spacer()
            }
        }
        .background(universalBackgroundColor)
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
            Text("Success!")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(universalAccentColor)
            
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
    
    private var activityTitle: String {
        return viewModel.activity.title?.isEmpty == false ? viewModel.activity.title! : (viewModel.selectedActivityType?.title ?? "Activity")
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var showShareSheet: Bool = false
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityConfirmationView(
        showShareSheet: $showShareSheet,
        onClose: {
            print("Close tapped")
        },
        onBack: {
            print("Back tapped")
        }
    )
    .environmentObject(appCache)
} 
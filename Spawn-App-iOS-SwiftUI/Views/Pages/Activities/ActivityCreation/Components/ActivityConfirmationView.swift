import SwiftUI

struct ActivityConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @Binding var showShareSheet: Bool
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
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
            
            Button(action: onClose) {
                Text("Return to Home")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
            }
        }
        .padding()
        .background(universalBackgroundColor)
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
        }
    )
    .environmentObject(appCache)
} 
import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Appearance")
                    .font(.headline)
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                
                Spacer()
                
                // Empty view for balance
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Settings sections
            ScrollView {
                VStack(spacing: 24) {
                    // Color Scheme section
                    SettingsSection(title: "Color Scheme") {
                        ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                            Button(action: {
                                themeService.setColorScheme(scheme)
                            }) {
                                HStack {
                                    Image(systemName: scheme.systemIcon)
                                        .font(.system(size: 18))
                                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                        .frame(width: 24, height: 24)
                                    
                                    Text(scheme.displayName)
                                        .font(.body)
                                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                    
                                    Spacer()
                                    
                                    if themeService.colorScheme == scheme {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                    }
                                }
                                .padding(.horizontal)
                                .frame(height: 44)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // Add divider between items except for the last one
                            if scheme != AppColorScheme.allCases.last {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Preview section
                    SettingsSection(title: "Preview") {
                        VStack(spacing: 16) {
                            // Light mode preview (top)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Light")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ThemePreviewCard(
                                    previewScheme: .light,
                                    themeService: themeService,
                                    environmentScheme: colorScheme
                                )
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            
                            // Dark mode preview (bottom)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dark")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ThemePreviewCard(
                                    previewScheme: .dark,
                                    themeService: themeService,
                                    environmentScheme: colorScheme
                                )
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .navigationBarHidden(true)
    }
}

// MARK: - Theme Preview Components
struct ThemePreviewCard: View {
    let previewScheme: ColorScheme
    let themeService: ThemeService
    let environmentScheme: ColorScheme
    
    private var mockUserId: UUID {
        UUID()
    }
    
    var body: some View {
        // Create a mock activity with different data for study theme
        let mockActivity = FullFeedActivityDTO(
            id: UUID(),
            title: "Coffee & Study",
            startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
            endTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()),
            location: Location(
                id: UUID(),
                name: "AMS Student Nest",
                latitude: 49.2672, longitude: -123.2500
            ),
            note: "Let's study together!",
            icon: "📚",
            category: .grind,
            creatorUser: BaseUserDTO.danielAgapov,
            participantUsers: [
                BaseUserDTO.danielAgapov,
                BaseUserDTO.danielLee
            ]
        )
        
        // Use the popup-style preview
        ActivityPopupPreviewView(
            activity: mockActivity,
            color: figmaSoftBlue,
            previewScheme: previewScheme
        )
    }
}

// MARK: - Activity Popup Preview (Top Portion Only)
struct ActivityPopupPreviewView: View {
    let activity: FullFeedActivityDTO
    let color: Color
    let previewScheme: ColorScheme
    @ObservedObject private var cardViewModel: ActivityCardViewModel
    
    init(activity: FullFeedActivityDTO, color: Color, previewScheme: ColorScheme) {
        self.activity = activity
        self.color = color
        self.previewScheme = previewScheme
        self.cardViewModel = ActivityCardViewModel(
            apiService: MockAPIService.isMocking ? MockAPIService(userId: UUID()) : APIService(),
            userId: UUID(),
            activity: activity
        )
    }
    
    private var buttonBackgroundColor: Color {
        switch previewScheme {
        case .light:
            return Color.white
        case .dark:
            return Color.black
        @unknown default:
            return Color.white
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Main card content (top portion only)
            VStack(alignment: .leading, spacing: 16) {
                // Event title and time
                titleAndTime
                
                // Spawn In button and attendees
                participationButtonView
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(color.opacity(0.97))
        .cornerRadius(20)
        .shadow(radius: 10)
        .colorScheme(previewScheme) // Force the color scheme for the entire preview
    }
    
    private var titleAndTime: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.title ?? (activity.creatorUser.name ?? activity.creatorUser.username) + "'s activity")
                .font(.onestSemiBold(size: 32))
                .foregroundColor(.white)
            Text("In 2 hours • " + getTimeDisplayString())
                .font(.onestSemiBold(size: 15))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    private var participationButtonView: some View {
        HStack {
            Button(action: {
                // Non-interactive for preview
            }) {
                HStack {
                    Image(systemName: "star.circle")
                        .foregroundColor(figmaSoftBlue)
                        .fontWeight(.bold)
                    Text("Spawn In!")
                        .font(.onestMedium(size: 18))
                        .foregroundColor(figmaSoftBlue)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(buttonBackgroundColor)
                .cornerRadius(12)
            }
            .disabled(true) // Make it non-interactive
            
            Spacer()
            
            // Use the actual ParticipantsImagesView component
            ParticipantsImagesView(activity: activity)
        }
    }
    
    private func getTimeDisplayString() -> String {
        guard let startTime = activity.startTime else { return "Time TBD" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
}

@available(iOS 17, *)
#Preview {
    AppearanceSettingsView()
} 

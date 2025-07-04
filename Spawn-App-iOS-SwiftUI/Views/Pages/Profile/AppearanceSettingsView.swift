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
            creatorUser: BaseUserDTO.jennifer,
            participantUsers: [
                BaseUserDTO.jennifer,
                BaseUserDTO.danielLee
            ]
        )
        
        // Use the actual ActivityCardView but in a non-interactive wrapper
        NonInteractiveActivityCardView(
            userId: mockUserId,
            activity: mockActivity,
            color: figmaSoftBlue,
            previewScheme: previewScheme
        )
    }
}

// MARK: - Non-Interactive Activity Card Wrapper
struct NonInteractiveActivityCardView: View {
    @ObservedObject var viewModel: ActivityCardViewModel
    var activity: FullFeedActivityDTO
    var color: Color
    let previewScheme: ColorScheme
    
    init(
        userId: UUID,
        activity: FullFeedActivityDTO,
        color: Color,
        previewScheme: ColorScheme
    ) {
        self.activity = activity
        self.color = color
        self.previewScheme = previewScheme
        self.viewModel = ActivityCardViewModel(
            apiService: MockAPIService.isMocking
                ? MockAPIService(userId: userId) : APIService(),
            userId: userId,
            activity: activity
        )
    }
    
    var body: some View {
        // Force the color scheme for the preview
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Row: Title, Participants
                ActivityCardTopRowView(activity: activity)
                // Location Row
                ActivityLocationView(activity: activity)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
            .onAppear {
                viewModel.fetchIsParticipating()
            }
            // Remove onTapGesture to make it non-interactive
            
            // Time Status Badge
            ActivityStatusView(activity: activity)
        }
        .preferredColorScheme(previewScheme)
    }
}

@available(iOS 17, *)
#Preview {
    AppearanceSettingsView()
} 

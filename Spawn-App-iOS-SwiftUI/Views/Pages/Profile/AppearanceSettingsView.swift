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
                            .buttonStyle(PlainButtonStyle())
                            
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
                            // Single preview that changes based on selected theme
                            VStack(alignment: .leading, spacing: 8) {
                                Text(getPreviewTitle())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ThemePreviewCard(
                                    previewScheme: getPreviewScheme(),
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
    
    // MARK: - Helper Functions
    private func getPreviewTitle() -> String {
        switch themeService.colorScheme {
        case .system:
            return colorScheme == .dark ? "Dark" : "Light"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    private func getPreviewScheme() -> ColorScheme {
        switch themeService.colorScheme {
        case .system:
            return colorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Theme Preview Components
struct ThemePreviewCard: View {
    let previewScheme: ColorScheme
    let themeService: ThemeService
    let environmentScheme: ColorScheme
    
    private var backgroundColor: Color {
        switch previewScheme {
        case .light:
            return Color(hex: "#FFFFFF")
        case .dark:
            return Color(hex: "#000000")
        @unknown default:
            return Color(hex: "#FFFFFF")
        }
    }
    
    private var textColor: Color {
        switch previewScheme {
        case .light:
            return Color(hex: "#1D1D1D")
        case .dark:
            return Color(hex: "#FFFFFF")
        @unknown default:
            return Color(hex: "#1D1D1D")
        }
    }
    
    private var secondaryTextColor: Color {
        switch previewScheme {
        case .light:
            return Color(hex: "#8E8484")
        case .dark:
            return Color(hex: "#A8A8A8")
        @unknown default:
            return Color(hex: "#8E8484")
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // First activity card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coffee & Study")
                            .font(.onestMedium(size: 16))
                            .foregroundColor(textColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 10))
                                .foregroundColor(secondaryTextColor)
                            
                            Text("AMS Student Nest")
                                .font(.onestRegular(size: 12))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Participant images
                    HStack(spacing: -6) {
                        Circle()
                            .fill(figmaSoftBlue)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("J")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Circle()
                            .fill(activityGreenHexCode.isEmpty ? .green : Color(hex: activityGreenHexCode))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("A")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.onestRegular(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Text("2:00 PM")
                            .font(.onestMedium(size: 12))
                            .foregroundColor(textColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Participants")
                            .font(.onestRegular(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Text("2/6")
                            .font(.onestMedium(size: 12))
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Duration")
                            .font(.onestRegular(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Text("2 hours")
                            .font(.onestMedium(size: 12))
                            .foregroundColor(textColor)
                    }
                }
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Second activity card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Basketball Game")
                            .font(.onestMedium(size: 16))
                            .foregroundColor(textColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 10))
                                .foregroundColor(secondaryTextColor)
                            
                            Text("Thunderbird Gym")
                                .font(.onestRegular(size: 12))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Participant images
                    HStack(spacing: -6) {
                        Circle()
                            .fill(Color(hex: activityRedHexCode))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("M")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Circle()
                            .fill(Color(hex: activityBlueHexCode))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("K")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Circle()
                            .fill(Color(hex: activityPurpleHexCode))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("S")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tomorrow")
                            .font(.onestRegular(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Text("6:00 PM")
                            .font(.onestMedium(size: 12))
                            .foregroundColor(textColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Participants")
                            .font(.onestRegular(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Text("4/8")
                            .font(.onestMedium(size: 12))
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Duration")
                            .font(.onestRegular(size: 10))
                            .foregroundColor(secondaryTextColor)
                        
                        Text("1.5 hours")
                            .font(.onestMedium(size: 12))
                            .foregroundColor(textColor)
                    }
                }
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

@available(iOS 17, *)
#Preview {
    AppearanceSettingsView()
} 
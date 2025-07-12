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
                }
                .padding(.horizontal)
            }
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .navigationBarHidden(true)
    }
}



@available(iOS 17, *)
#Preview {
    AppearanceSettingsView()
} 

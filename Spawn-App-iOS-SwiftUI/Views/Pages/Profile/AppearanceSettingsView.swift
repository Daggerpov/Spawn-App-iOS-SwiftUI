import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Appearance")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
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
                                        .foregroundColor(universalAccentColor)
                                        .frame(width: 24, height: 24)
                                    
                                    Text(scheme.displayName)
                                        .font(.body)
                                        .foregroundColor(universalAccentColor)
                                    
                                    Spacer()
                                    
                                    if themeService.colorScheme == scheme {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(universalAccentColor)
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
                            // Light mode preview
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Light")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .frame(height: 60)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.black)
                                                    .frame(height: 8)
                                                    .padding(.horizontal, 8)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.6))
                                                    .frame(height: 6)
                                                    .padding(.horizontal, 8)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.4))
                                                    .frame(height: 6)
                                                    .padding(.horizontal, 8)
                                            }
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dark")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black)
                                        .frame(height: 60)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white)
                                                    .frame(height: 8)
                                                    .padding(.horizontal, 8)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.8))
                                                    .frame(height: 6)
                                                    .padding(.horizontal, 8)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.6))
                                                    .frame(height: 6)
                                                    .padding(.horizontal, 8)
                                            }
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
    }
}

@available(iOS 17, *)
#Preview {
    AppearanceSettingsView()
} 
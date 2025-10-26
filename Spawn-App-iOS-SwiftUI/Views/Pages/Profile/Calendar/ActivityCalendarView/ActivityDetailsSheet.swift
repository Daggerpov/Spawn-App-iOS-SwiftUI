import SwiftUI

struct ActivityDetailsSheet: View {
    let activity: CalendarActivityDTO
    @StateObject var userAuth: UserAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Activity header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity")
                            .font(.onestSemiBold(size: 24))
                            .foregroundColor(universalAccentColor)
                        
                        Text(DateFormatter.dayMonthYear.string(from: activity.dateAsDate))
                            .font(.onestMedium(size: 16))
                            .foregroundColor(figmaBlack300)
                    }
                    
                    Spacer()
                    
                    // Activity icon
                    if let icon = activity.icon, !icon.isEmpty {
                        Text(icon)
                            .font(.onestMedium(size: 40))
                    } else {
                        Text("⭐️")
                            .font(.onestMedium(size: 40))
                            .foregroundColor(universalAccentColor)
                    }
                }
                .padding(.horizontal, 20)
                
                // Activity details
                VStack(alignment: .leading, spacing: 16) {
                    if let activityId = activity.activityId {
                        Text("Activity ID: \(activityId.uuidString)")
                            .font(.onestMedium(size: 14))
                            .foregroundColor(figmaBlack300)
                    }
                    
                    if let colorHex = activity.colorHexCode {
                        HStack {
                            Text("Color:")
                                .font(.onestMedium(size: 14))
                                .foregroundColor(figmaBlack300)
                            
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 20, height: 20)
                            
                            Text(colorHex)
                                .font(.onestMedium(size: 14))
                                .foregroundColor(figmaBlack300)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(universalAccentColor)
                        .cornerRadius(universalRectangleCornerRadius)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
        }
    }
}


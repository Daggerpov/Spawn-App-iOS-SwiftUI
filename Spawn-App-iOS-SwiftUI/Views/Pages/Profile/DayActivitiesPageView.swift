import SwiftUI

struct DayActivitiesPageView: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    var body: some View {
        ZStack {
            // White background matching Figma design
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Activities list
                if activities.isEmpty {
                    emptyStateView
                } else {
                    activitiesListView
                }
                
                Spacer()
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 32) {
            // Back button
            Button(action: onDismiss) {
                Text("􀆉")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
            }
            
            // Title
            Text("Events - \(formattedDate)")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
            
            // Invisible spacer to balance the layout
            Text("􀆉")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                .opacity(0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    private var activitiesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(activities, id: \.id) { activity in
                    DayActivityCard(
                        activity: activity,
                        color: getColorForActivity(activity),
                        onTap: {
                            onActivitySelected(activity)
                        }
                    )
                    .padding(.horizontal, 32)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Events Found")
                .font(.onestSemiBold(size: 24))
                .foregroundColor(.primary)
            
            Text("There are no activities scheduled for this day.")
                .font(.onestRegular(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    private func getColorForActivity(_ activity: CalendarActivityDTO) -> Color {
        // If we have a color hex code from the backend, use it
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Otherwise, use the activity color based on ID
        guard let activityId = activity.activityId else {
            return figmaBlue // Default color
        }
        
        return getActivityColor(for: activityId)
    }
}

// MARK: - Day Activity Card
struct DayActivityCard: View {
    let activity: CalendarActivityDTO
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sample Activity")
                        .font(.onestSemiBold(size: 17))
                        .foregroundColor(textColor)
                    
                    Text("Activity Location • \(formattedDate)")
                        .font(.onestMedium(size: 13))
                        .foregroundColor(subtitleColor)
                }
                
                Spacer()
                
                // Participant count and avatars
                HStack(spacing: -8) {
                    // Participant count
                    VStack(spacing: 0) {
                        Text("+2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(participantCountColor)
                    }
                    .frame(width: 33.60, height: 33.60)
                    .background(.white)
                    .clipShape(Circle())
                    
                    // Avatar circles (placeholder)
                    ForEach(0..<2, id: \.self) { _ in
                        Circle()
                            .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .frame(width: 33.53, height: 34.26)
                            .shadow(color: Color.black.opacity(0.25), radius: 3.22, x: 0, y: 1.29)
                    }
                }
            }
            .padding(EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: activity.date)
    }
    
    private var textColor: Color {
        // Use white text for darker backgrounds, black for lighter backgrounds
        if color == figmaBlue || color.isDark {
            return .white
        } else {
            return Color(red: 0, green: 0, blue: 0, opacity: 0.75)
        }
    }
    
    private var subtitleColor: Color {
        if color == figmaBlue || color.isDark {
            return Color.white.opacity(0.80)
        } else {
            return Color(red: 0, green: 0, blue: 0, opacity: 0.60)
        }
    }
    
    private var participantCountColor: Color {
        if color == figmaBlue || color.isDark {
            return figmaBlue
        } else {
            return Color(red: 0.13, green: 0.25, blue: 0.19)
        }
    }
}

// MARK: - Color Extension
extension Color {
    var isDark: Bool {
        // Convert to RGB and check if it's generally dark
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate luminance
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance < 0.5
    }
}

// MARK: - Previews
#if DEBUG
struct DayActivitiesPageView_Previews: PreviewProvider {
    static var previews: some View {
        DayActivitiesPageView(
            date: Date(),
            activities: [
                CalendarActivityDTO(
                    id: UUID(),
                    date: Date(),
                    icon: "🎉",
                    colorHexCode: "#3575FF",
                    activityId: UUID()
                ),
                CalendarActivityDTO(
                    id: UUID(),
                    date: Date(),
                    icon: "🥾",
                    colorHexCode: "#80FF75",
                    activityId: UUID()
                )
            ],
            onDismiss: {},
            onActivitySelected: { _ in }
        )
    }
}
#endif 

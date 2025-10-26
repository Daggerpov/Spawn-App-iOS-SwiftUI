import SwiftUI

// Individual day cell
struct DayCell: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let isToday: Bool
    let onTapped: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }
    
    private var activityBackgroundColor: Color {
        if let firstActivity = activities.first {
            return activityColor(for: firstActivity)
        }
        return Color.gray.opacity(0.05)
    }
    
    var body: some View {
        Button(action: onTapped) {
            ZStack {
                // Main calendar cell background
                RoundedRectangle(cornerRadius: 12)
                    .fill(activities.isEmpty ? figmaCalendarDayIcon : activityBackgroundColor)
                    .frame(width: 86, height: 86)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday ? universalAccentColor : Color.clear, lineWidth: 2)
                    )
                
                // Activity display (centered)
                if !activities.isEmpty {
                    if activities.count == 1 {
                        // Single activity - show its icon
                        // Add safety check to prevent force unwrapping crash
                        if let firstActivity = activities.first {
                            activityIconView(for: firstActivity)
                        } else {
                            EmptyView()
                        }
                    } else {
                        // Multiple activities - show count or multiple icons
                        multipleActivitiesView
                    }
                }
                
                // Date number badge (positioned in top-right corner)
                VStack {
                    HStack {
                        Spacer()
                        Text(dayNumber)
                            .font(.onestMedium(size: 12))
                            .foregroundColor(.black)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func activityIconView(for activity: CalendarActivityDTO) -> some View {
        // Activity icon (centered in the cell, no background since cell has the color)
        if let icon = activity.icon, !icon.isEmpty {
            Text(icon)
                .font(.custom("Onest", size: 40).weight(.medium))
                .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
        } else {
            Text("⭐️")
                .font(.custom("Onest", size: 40).weight(.medium))
                .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
        }
    }
    

    
    @ViewBuilder
    private var multipleActivitiesView: some View {
        if activities.count == 2 {
            // Show 2 icons side by side (matching Figma design)
            HStack(spacing: -5) {
                ForEach(activities.prefix(2), id: \.id) { activity in
                    if let icon = activity.icon, !icon.isEmpty {
                        Text(icon)
                            .font(.custom("Onest", size: 30).weight(.medium))
                            .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                    } else {
                        Text("⭐️")
                            .font(.custom("Onest", size: 30).weight(.medium))
                            .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                    }
                }
            }
        } else {
            // For 3+ activities, show the first icon larger
            if let firstActivity = activities.first, let icon = firstActivity.icon, !icon.isEmpty {
                Text(icon)
                    .font(.custom("Onest", size: 40).weight(.medium))
                    .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
            } else {
                Text("⭐️")
                    .font(.custom("Onest", size: 40).weight(.medium))
                    .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
            }
        }
    }
    
    private func activityColor(for activity: CalendarActivityDTO) -> Color {
        // Use custom color if available
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Otherwise use activity color based on ID
        if let activityId = activity.activityId {
            return getActivityColor(for: activityId)
        }
        
        return .gray
    }
}


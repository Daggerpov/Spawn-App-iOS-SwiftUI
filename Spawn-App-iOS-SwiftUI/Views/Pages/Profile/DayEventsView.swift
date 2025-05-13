import SwiftUI

struct DayEventsView: View {
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onEventSelected: (CalendarActivityDTO) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let firstActivity = activities.first {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM d, yyyy"
                    Text(formatter.string(from: firstActivity.date))
                        .font(.headline)
                        .padding(.leading)
                } else {
                    Text("Events")
                        .font(.headline)
                        .padding(.leading)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Done")
                        .foregroundColor(universalAccentColor)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 16)
            
            Divider()
            
            // Events list
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(activities, id: \.id) { activity in
                        EventCardForCalendar(activity: activity)
                            .onTapGesture {
                                onEventSelected(activity)
                            }
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct EventCardForCalendar: View {
    let activity: CalendarActivityDTO
    
    var body: some View {
        HStack(spacing: 0) {
            // Left color band
            activityColor(for: activity)
                .frame(width: 8)
                .cornerRadius(8, corners: [.topLeft, .bottomLeft])
            
            // Card content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Icon and title
                    activityIcon(for: activity)
                        .font(.headline)
                        .foregroundColor(activityColor(for: activity))
                        .padding(.trailing, 4)
                    
                    Text(activity.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Time
                    if let time = activity.formattedTime {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Description or location
                if let location = activity.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                // Participants preview
                HStack {
                    // This is a placeholder for participants
                    // In a real implementation, you would fetch and display user avatars here
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    Text("Participants info")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    private func activityColor(for activity: CalendarActivityDTO) -> Color {
        // First check if activity has a custom color hex code
        if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
            return Color(hex: colorHexCode)
        }
        
        // Fallback to category color
        guard let category = activity.eventCategory else {
            return Color.gray.opacity(0.6) // Default color for null category
        }
        return category.color()
    }
    
    private func activityIcon(for activity: CalendarActivityDTO) -> some View {
        Group {
            // If we have an icon from the backend, use it directly
            if let icon = activity.icon, !icon.isEmpty {
                Text(icon)
                    .font(.system(size: 16))
            } else {
                // Fallback to system icon from the EventCategory enum
                Image(systemName: activity.eventCategory?.systemIcon() ?? "circle.fill")
                    .font(.system(size: 14))
            }
        }
    }
}

#if DEBUG
struct DayEventsView_Previews: PreviewProvider {
    static var previews: some View {
        DayEventsView(
            activities: [
                // Sample activities would go here
            ],
            onDismiss: {},
            onEventSelected: { _ in }
        )
    }
}
#endif 
import SwiftUI

struct DayActivitiesPageView: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Dark background matching Figma design
            Color(red: 0.12, green: 0.12, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                // Activities content
                if activities.isEmpty {
                    emptyStateView
                } else {
                    activitiesScrollView
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("🔥 DayActivitiesPageView: appeared with \(activities.count) activities")
            print("🔥 DayActivitiesPageView: date is \(formattedDate)")
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 32) {
            // Back button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
                onDismiss()
            }) {
                Text("􀆉")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Title
            Text("Events - \(formattedDate)")
                .font(.custom("Onest", size: 20).weight(.semibold))
                .foregroundColor(.white)
            
            // Invisible spacer to balance the layout
            Text("􀆉")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .opacity(0)
        }
        .frame(width: 375)
    }
    
    private var activitiesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                    FigmaActivityCard(
                        activity: activity,
                        color: getColorForActivity(activity, index: index),
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
                .font(.custom("Onest", size: 24).weight(.semibold))
                .foregroundColor(.white)
            
            Text("There are no activities scheduled for this day.")
                .font(.custom("Onest", size: 16))
                .foregroundColor(.white.opacity(0.7))
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
    
    private func getColorForActivity(_ activity: CalendarActivityDTO, index: Int) -> Color {
        // If we have a color hex code from the backend, use it
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Otherwise, use the activity color based on ID
        guard let activityId = activity.activityId else {
            // Use alternating colors from the Figma design
            return index % 2 == 0 ? Color(red: 0.21, green: 0.46, blue: 1) : Color(red: 0.50, green: 1, blue: 0.75)
        }
        
        return getActivityColor(for: activityId)
    }
}

// MARK: - Figma Activity Card matching the design
struct FigmaActivityCard: View {
    let activity: CalendarActivityDTO
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Activity")
                        .font(.custom("Onest", size: 17).weight(.semibold))
                        .foregroundColor(textColor)
                    
                    Text("Event • \(formattedDate)")
                        .font(.custom("Onest", size: 13).weight(.medium))
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
            .frame(width: 364)
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
        // Use white text for blue background, black text for light backgrounds
        if color == Color(red: 0.21, green: 0.46, blue: 1) {
            return .white
        } else {
            return Color(red: 0, green: 0, blue: 0).opacity(0.75)
        }
    }
    
    private var subtitleColor: Color {
        if color == Color(red: 0.21, green: 0.46, blue: 1) {
            return Color(red: 0, green: 0, blue: 0).opacity(0.80)
        } else {
            return Color(red: 1, green: 1, blue: 1).opacity(0.60)
        }
    }
    
    private var participantCountColor: Color {
        if color == Color(red: 0.21, green: 0.46, blue: 1) {
            return Color(red: 0.21, green: 0.46, blue: 1)
        } else {
            return Color(red: 0.13, green: 0.25, blue: 0.19)
        }
    }
}

// MARK: - Color Extension for hex support
extension Color {
    var isDark: Bool {
        guard let components = cgColor?.components else { return false }
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        
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
					title: "asdf",
                    icon: "🎉",
                    colorHexCode: "#3575FF",
                    activityId: UUID()
                ),
                CalendarActivityDTO(
                    id: UUID(),
                    date: Date(),
					title: "asdf",
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

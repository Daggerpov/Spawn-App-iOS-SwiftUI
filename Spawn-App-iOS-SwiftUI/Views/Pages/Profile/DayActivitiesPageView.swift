import SwiftUI

struct DayActivitiesPageView: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var userAuth = UserAuthViewModel.shared
    @State private var showActivityDetails: Bool = false
    
    var body: some View {
        ZStack {
            // Theme-dependent background
            universalBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button and title
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(universalAccentColor)
                    }
                    
                    Spacer()
                    
                    Text("Events - \(formattedDate)")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Activity Cards
                ScrollView {
                    VStack(spacing: 16) {
                        if activities.count >= 1 {
                            FigmaActivityCard(
                                activity: activities[0],
                                isFirst: true,
                                onTap: {
                                    handleActivitySelection(activities[0])
                                }
                            )
                        }
                        
                        if activities.count >= 2 {
                            FigmaActivityCard(
                                activity: activities[1],
                                isFirst: false,
                                onTap: {
                                    handleActivitySelection(activities[1])
                                }
                            )
                        }
                        
                        // Show additional activities if there are more than 2
                        ForEach(Array(activities.dropFirst(2).enumerated()), id: \.offset) { index, activity in
                            FigmaActivityCard(
                                activity: activity,
                                isFirst: (index + 2) % 2 == 0,
                                onTap: {
                                    handleActivitySelection(activity)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Safe area padding
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("🔥 DayActivitiesPageView: appeared with \(activities.count) activities")
            print("🔥 DayActivitiesPageView: date is \(formattedDate)")
            
            // Enhanced debug logging for activityId values
            print("🔥 DayActivitiesPageView: DETAILED ACTIVITY DEBUG:")
            for (index, activity) in activities.enumerated() {
                print("🔥   Activity \(index + 1):")
                print("🔥     - id: \(activity.id)")
                print("🔥     - title: \(activity.title ?? "nil")")
                print("🔥     - date: \(activity.date)")
                print("🔥     - icon: \(activity.icon ?? "nil")")
                print("🔥     - colorHexCode: \(activity.colorHexCode ?? "nil")")
                print("🔥     - activityId: \(activity.activityId?.uuidString ?? "nil") ⚠️")
                print("🔥     ---")
            }
            
            // Check if any activities have nil activityId
            let activitiesWithNilId = activities.filter { $0.activityId == nil }
            if !activitiesWithNilId.isEmpty {
                print("🚨 DayActivitiesPageView: WARNING - \(activitiesWithNilId.count) activities have nil activityId!")
                print("🚨 This will prevent loading full activity details.")
            } else {
                print("✅ DayActivitiesPageView: All activities have valid activityId values")
            }
        }
        .sheet(isPresented: $showActivityDetails) {
            if let activity = profileViewModel.selectedActivity {
                // Use the same color scheme as ActivityCardView would
                let activityColor = activity.isSelfOwned == true ?
                universalAccentColor : getActivityColor(for: activity.id)

                ActivityDetailModalView(
                    activity: activity,
                    activityColor: activityColor,
                    onDismiss: {
                        showActivityDetails = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleActivitySelection(_ activity: CalendarActivityDTO) {
        print("🔥 DayActivitiesPageView: Activity selected: \(activity.title ?? "Unknown")")
        
        Task {
            if let activityId = activity.activityId,
               let _ = await profileViewModel.fetchActivityDetails(activityId: activityId) {
                await MainActor.run {
                    showActivityDetails = true
                }
            } else {
                print("🚨 DayActivitiesPageView: Failed to fetch activity details for activityId: \(activity.activityId?.uuidString ?? "nil")")
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Figma Activity Card matching the exact design
struct FigmaActivityCard: View {
    let activity: CalendarActivityDTO
    let isFirst: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var cardColor: Color {
        return isFirst ? Color(red: 0.21, green: 0.46, blue: 1) : Color(red: 0.50, green: 1, blue: 0.75)
    }
    
    private var textColor: Color {
        return isFirst ? .white : Color(red: 0, green: 0, blue: 0).opacity(0.75)
    }
    
    private var subtitleColor: Color {
        return isFirst ? Color(red: 1, green: 1, blue: 1).opacity(0.80) : Color(red: 0, green: 0, blue: 0).opacity(0.60)
    }
    
    private var participantCountColor: Color {
        return isFirst ? Color(red: 0.21, green: 0.46, blue: 1) : Color(red: 0.13, green: 0.25, blue: 0.19)
    }
    
    // Shadow configuration for different modes
    private var shadowColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.3)
        case .light:
            return Color.black.opacity(0.25)
        @unknown default:
            return Color.black.opacity(0.25)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.title ?? "Sample Activity")
                        .font(Font.custom("Onest", size: 17).weight(.semibold))
                        .foregroundColor(textColor)
                    
                    Text("\(activity.title ?? "Activity Location") • \(formattedDate)")
                        .font(Font.custom("Onest", size: 13).weight(.medium))
                        .foregroundColor(subtitleColor)
                }
                
                VStack(spacing: 8.40) {
                    Text("+2")
                        .font(Font.custom("SF Pro Display", size: 12).weight(.bold))
                        .foregroundColor(participantCountColor)
                }
                .padding(EdgeInsets(top: 45.37, leading: 42.01, bottom: 45.37, trailing: 42.01))
                .frame(width: 33.60, height: 33.60)
                .background(.white)
                .cornerRadius(51.67)
                
                Ellipse()
                    .foregroundColor(.clear)
                    .frame(width: 33.53, height: 34.26)
                    .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 3.22, y: 1.29)
                
                Ellipse()
                    .foregroundColor(.clear)
                    .frame(width: 33.53, height: 34.26)
                    .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 3.22, y: 1.29)
            }
            .padding(EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16))
            .frame(width: 364)
            .background(cardColor)
            .cornerRadius(12)
            .shadow(color: shadowColor, radius: 8, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: activity.date)
    }
}

// MARK: - Preview
@available(iOS 17, *)
struct DayActivitiesPageView_Previews: PreviewProvider {
    static var previews: some View {
        DayActivitiesPageView(
            date: Date(),
            activities: [
                CalendarActivityDTO(
                    id: UUID(),
                    date: Date(),
                    title: "Sample Activity",
                    icon: "🎉",
                    colorHexCode: "#3575FF",
                    activityId: UUID()
                ),
                CalendarActivityDTO(
                    id: UUID(),
                    date: Date(),
                    title: "Another Activity",
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

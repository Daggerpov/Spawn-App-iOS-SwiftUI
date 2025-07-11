import SwiftUI

struct DayActivitiesPageView: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Group {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 926)
                    .background(.white)
                    .offset(x: 0, y: 0)
                
                // Header with back button and title
                HStack(spacing: 32) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss()
                    }) {
                        Text("􀆉")
                            .font(Font.custom("SF Pro Display", size: 20).weight(.semibold))
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    }
                    Text("Events - \(formattedDate)")
                        .font(Font.custom("Onest", size: 20).weight(.semibold))
                        .lineSpacing(24)
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    Text("􀆉")
                        .font(Font.custom("SF Pro Display", size: 20).weight(.semibold))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                        .opacity(0)
                }
                .frame(width: 375)
                .offset(x: -2.50, y: -379)
                
                // Status bar simulation
                HStack(alignment: .top, spacing: 32) {
                    HStack(alignment: .bottom, spacing: 10) {
                        Text("9:41")
                            .font(Font.custom("SF Pro Text", size: 20).weight(.semibold))
                            .lineSpacing(20)
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    }
                    .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
                    .frame(width: 77.14)
                    .cornerRadius(24)
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 192)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                            .cornerRadius(30)
                    }
                    HStack(alignment: .bottom, spacing: 4.95) {
                        // Battery and other status icons would go here
                    }
                    .frame(height: 37)
                }
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                .frame(width: 428, height: 37)
                .offset(x: 0, y: -444.50)
                
                // Bottom navigation bar
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 8) {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 4)
                                .background(Color(red: 0.66, green: 0.63, blue: 0.63))
                                .cornerRadius(200)
                                .opacity(0)
                            VStack(spacing: 8) {
                                ZStack {
                                    // Home icon placeholder
                                }
                                .frame(width: 32, height: 32)
                                Text("Home")
                                    .font(Font.custom("Onest", size: 13).weight(.medium))
                                    .foregroundColor(Color(red: 0.66, green: 0.63, blue: 0.63))
                            }
                        }
                        .frame(width: 72.80)
                        
                        VStack(spacing: 8) {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 4)
                                .background(Color(red: 0.66, green: 0.63, blue: 0.63))
                                .cornerRadius(200)
                                .opacity(0)
                            VStack(spacing: 8) {
                                ZStack {
                                    // Map icon placeholder
                                }
                                .frame(width: 32, height: 32)
                                Text("Map")
                                    .font(Font.custom("Onest", size: 13).weight(.medium))
                                    .foregroundColor(Color(red: 0.66, green: 0.63, blue: 0.63))
                            }
                        }
                        .frame(width: 72.80)
                        
                        VStack(spacing: 8) {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 4)
                                .background(Color(red: 0.66, green: 0.63, blue: 0.63))
                                .cornerRadius(200)
                                .opacity(0)
                            VStack(spacing: 8) {
                                ZStack {
                                    // Activities icon placeholder
                                }
                                .frame(width: 32, height: 32)
                                Text("Activities")
                                    .font(Font.custom("Onest", size: 13).weight(.medium))
                                    .foregroundColor(Color(red: 0.66, green: 0.63, blue: 0.63))
                            }
                        }
                        .frame(width: 72.80)
                        
                        VStack(spacing: 8) {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 4)
                                .background(Color(red: 0.66, green: 0.63, blue: 0.63))
                                .cornerRadius(200)
                                .opacity(0)
                            VStack(spacing: 8) {
                                ZStack {
                                    // Friends icon placeholder
                                }
                                .frame(width: 32, height: 32)
                                Text("Friends")
                                    .font(Font.custom("Onest", size: 13).weight(.medium))
                                    .foregroundColor(Color(red: 0.66, green: 0.63, blue: 0.63))
                            }
                        }
                        .frame(width: 72.80)
                        
                        VStack(spacing: 8) {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 4)
                                .background(Color(red: 0.42, green: 0.51, blue: 0.98))
                                .cornerRadius(100)
                            VStack(spacing: 8) {
                                ZStack {
                                    // Profile icon placeholder
                                }
                                .frame(width: 32, height: 32)
                                Text("Profile")
                                    .font(Font.custom("Onest", size: 13).weight(.medium))
                                    .foregroundColor(Color(red: 0.42, green: 0.51, blue: 0.98))
                            }
                        }
                        .frame(width: 72.80)
                    }
                    .padding(EdgeInsets(top: 0, leading: 32, bottom: 12, trailing: 32))
                    .background(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 134, height: 5)
                            .background(Color(red: 0.66, green: 0.63, blue: 0.63))
                            .cornerRadius(100)
                    }
                    .padding(EdgeInsets(top: 8, leading: 147, bottom: 8, trailing: 147))
                    .background(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                }
                .frame(width: 428)
                .offset(x: 0, y: 414)
                
                // Activity Cards
                if activities.count >= 1 {
                    FigmaActivityCard(
                        activity: activities[0],
                        isFirst: true,
                        onTap: {
                            onActivitySelected(activities[0])
                        }
                    )
                    .offset(x: 0, y: -303.50)
                }
                
                if activities.count >= 2 {
                    FigmaActivityCard(
                        activity: activities[1],
                        isFirst: false,
                        onTap: {
                            onActivitySelected(activities[1])
                        }
                    )
                    .offset(x: 0, y: -220.50)
                }
            }
        }
        .frame(width: 428, height: 926)
        .background(.white)
        .cornerRadius(44)
        .navigationBarHidden(true)
        .onAppear {
            print("🔥 DayActivitiesPageView: appeared with \(activities.count) activities")
            print("🔥 DayActivitiesPageView: date is \(formattedDate)")
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
            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2)
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

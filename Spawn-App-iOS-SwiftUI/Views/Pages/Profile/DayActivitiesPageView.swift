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
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 428, height: 926)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .ignoresSafeArea()
            
            // Header with back button and title
            HStack(spacing: 32) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    onDismiss()
                }) {
                    Text("􀆉")
                        .font(Font.custom("SF Pro Display", size: 20).weight(.semibold))
                        .foregroundColor(.white)
                }
                
                Text("Events - \(formattedDate)")
                    .font(Font.custom("Onest", size: 20).weight(.semibold))
                    .lineSpacing(24)
                    .foregroundColor(.white)
                
                Text("􀆉")
                    .font(Font.custom("SF Pro Display", size: 20).weight(.semibold))
                    .foregroundColor(.white)
                    .opacity(0)
            }
            .frame(width: 375)
            .offset(x: -2.50, y: -379)
            
            // Activity Cards
            if !activities.isEmpty {
                ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                    FigmaActivityCard(
                        activity: activity,
                        index: index,
                        onTap: {
                            onActivitySelected(activity)
                        }
                    )
                    .offset(x: 0, y: index == 0 ? -303.50 : -220.50)
                }
            }
        }
        .frame(width: 428, height: 926)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
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
    let index: Int
    let onTap: () -> Void
    
    private var cardColor: Color {
        // Alternating colors as per Figma design
        return index % 2 == 0 ? Color(red: 0.21, green: 0.46, blue: 1) : Color(red: 0.50, green: 1, blue: 0.75)
    }
    
    private var textColor: Color {
        // White text for blue background, black text for light green background
        return index % 2 == 0 ? .white : Color(red: 0, green: 0, blue: 0).opacity(0.75)
    }
    
    private var subtitleColor: Color {
        return index % 2 == 0 ? Color(red: 0, green: 0, blue: 0).opacity(0.80) : Color(red: 1, green: 1, blue: 1).opacity(0.60)
    }
    
    private var participantCountColor: Color {
        return index % 2 == 0 ? Color(red: 0.21, green: 0.46, blue: 1) : Color(red: 0.13, green: 0.25, blue: 0.19)
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
                
                Spacer()
                
                // Participant count
                VStack(spacing: 8.40) {
                    Text("+2")
                        .font(Font.custom("SF Pro Display", size: 12).weight(.bold))
                        .foregroundColor(participantCountColor)
                }
                .padding(EdgeInsets(top: 10.81, leading: 10.80, bottom: 10.81, trailing: 10.80))
                .frame(width: 33.60, height: 33.60)
                .background(.white)
                .cornerRadius(51.67)
                
                // Avatar circles
                ForEach(0..<2, id: \.self) { _ in
                    Ellipse()
                        .foregroundColor(.clear)
                        .frame(width: 33.53, height: 34.26)
                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 3.22, y: 1.29)
                }
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

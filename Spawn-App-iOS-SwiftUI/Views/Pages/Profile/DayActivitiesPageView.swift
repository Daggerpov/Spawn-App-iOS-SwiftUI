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
        ZStack() {
            Group {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 926)
                    .background(.white)
                    .offset(x: 0, y: 0)
                
                HStack(spacing: 32) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
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
                
                // Layout rectangles
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
            }
            
            Group {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
            }
            
            Group {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 428, height: 56)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0))
                    .offset(x: 428, y: -379)
                
                // Status bar
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
                        // Empty space for battery indicator
                    }
                    .frame(height: 37)
                }
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                .frame(width: 428, height: 37)
                .offset(x: 0, y: -444.50)
                
                // Bottom navigation
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
                                ZStack() {
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
                                ZStack() {
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
                                ZStack() {
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
                                ZStack() {
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
                                ZStack() {
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
                
                // First activity card (blue)
                Button(action: {
                    if activities.count > 0 {
                        handleActivitySelection(activities[0])
                    }
                }) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(activities.count > 0 ? (activities[0].title ?? "Sample Activity") : "Sample Activity")
                                .font(Font.custom("Onest", size: 17).weight(.semibold))
                                .foregroundColor(.white)
                            Text("\(activities.count > 0 ? (activities[0].title ?? "Activity Location") : "Activity Location") • \(activities.count > 0 ? formattedActivityDate(activities[0].dateAsDate) : "April 28")")
                                .font(Font.custom("Onest", size: 13).weight(.medium))
                                .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                        }
                        VStack(spacing: 8.40) {
                            Text("+2")
                                .font(Font.custom("SF Pro Display", size: 12).weight(.bold))
                                .foregroundColor(Color(red: 0.21, green: 0.46, blue: 1))
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
                    .background(Color(red: 0.21, green: 0.46, blue: 1))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2)
                }
                .offset(x: 0, y: -303.50)
                
                // Second activity card (green)
                Button(action: {
                    if activities.count > 1 {
                        handleActivitySelection(activities[1])
                    }
                }) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(activities.count > 1 ? (activities[1].title ?? "Sample Activity") : "Sample Activity")
                                .font(Font.custom("Onest", size: 17).weight(.semibold))
                                .foregroundColor(Color(red: 0, green: 0, blue: 0).opacity(0.75))
                            Text("\(activities.count > 1 ? (activities[1].title ?? "Activity Location") : "Activity Location") • \(activities.count > 1 ? formattedActivityDate(activities[1].dateAsDate) : "April 28")")
                                .font(Font.custom("Onest", size: 13).weight(.medium))
                                .foregroundColor(Color(red: 0, green: 0, blue: 0).opacity(0.60))
                        }
                        VStack(spacing: 8.40) {
                            Text("+2")
                                .font(Font.custom("SF Pro Display", size: 12).weight(.bold))
                                .foregroundColor(Color(red: 0.13, green: 0.25, blue: 0.19))
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
                    .background(Color(red: 0.50, green: 1, blue: 0.75))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2)
                }
                .offset(x: 0, y: -220.50)
                
                // Second status bar
                HStack(alignment: .top, spacing: 32) {
                    HStack(alignment: .bottom, spacing: 10) {
                        Text("2:05")
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
                            .background(.black)
                            .cornerRadius(30)
                    }
                    
                    HStack(alignment: .bottom, spacing: 4.95) {
                        // Empty space for battery indicator
                    }
                    .frame(height: 37)
                }
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                .frame(width: 428, height: 37)
                .offset(x: 0, y: -444.50)
            }
        }
        .frame(width: 428, height: 926)
        .background(.white)
        .cornerRadius(44)
        .navigationBarHidden(true)
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
        .onAppear {
            // View appeared
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleActivitySelection(_ activity: CalendarActivityDTO) {
        Task {
            if let activityId = activity.activityId,
               let _ = await profileViewModel.fetchActivityDetails(activityId: activityId) {
                await MainActor.run {
                    showActivityDetails = true
                }
            }
        }
	}
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    private func formattedActivityDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
@available(iOS 17, *)
struct DayActivitiesPageView_Previews: PreviewProvider {
    static var previews: some View {
        DayActivitiesPageView(
            date: Date(),
            activities: [
                CalendarActivityDTO.create(
                    id: UUID(),
                    date: Date(),
                    title: "Sample Activity",
                    icon: "🎉",
                    colorHexCode: "#3575FF",
                    activityId: UUID()
                ),
                CalendarActivityDTO.create(
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

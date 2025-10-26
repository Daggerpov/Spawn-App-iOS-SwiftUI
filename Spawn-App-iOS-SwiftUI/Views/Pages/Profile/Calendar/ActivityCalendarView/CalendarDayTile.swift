import SwiftUI

struct CalendarDayTile: View {
    let day: Date
    let activities: [CalendarActivityDTO]
    let isCurrentMonth: Bool
    let tileSize: CGFloat
    let onDayTapped: ([CalendarActivityDTO]) -> Void
    
    private let cornerRadius: CGFloat = 12.34
    
    private var dayNumber: String {
        String(Calendar.current.component(.day, from: day))
    }
    
    var body: some View {
        ZStack {
            if isCurrentMonth {
                // Background rectangle
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(activityBackgroundColor)
                    .frame(width: tileSize, height: tileSize)
                    .shadow(color: Color.black.opacity(0.1), radius: 12.34, x: 0, y: 3.09)
                    .overlay(
                        // Blue border overlay for current day
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .inset(by: 1)
                            .stroke(isToday ? figmaBlue : Color.clear, lineWidth: 2)
                    )
                    .overlay(
                        // Activity content
                        VStack(spacing: 4) {
                            if activities.count == 1 {
                                // Single activity emoji
                                activityEmoji(for: activities[0])
                                    .font(.onestMedium(size: tileSize * 0.57)) // Scale based on tile size
                                    .foregroundColor(figmaBlack300)
                            } else if activities.count > 1 {
                                // Multiple activities - show first two emojis
                                HStack(spacing: 2) {
                                    activityEmoji(for: activities[0])
                                        .font(.onestMedium(size: tileSize * 0.43)) // Scale based on tile size
                                        .foregroundColor(figmaBlack300)
                                    
                                    if activities.count > 1 {
                                        activityEmoji(for: activities[1])
                                            .font(.onestMedium(size: tileSize * 0.43)) // Scale based on tile size
                                            .foregroundColor(figmaBlack300)
                                    }
                                }
                            }
                        }
                    )
                    .overlay(
                        // Date number badge (positioned in top-right corner)
                        VStack {
                            HStack {
                                Spacer()
                                Text(dayNumber)
                                    .font(.onestMedium(size: max(10, tileSize * 0.12))) // Scale based on tile size with minimum
                                    .foregroundColor(.black)
                                    .padding(4)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                            Spacer()
                        }
                    )
                    .onTapGesture {
                        if !activities.isEmpty {
                            onDayTapped(activities)
                        }
                    }
            } else {
                // Days outside current month - invisible
                Color.clear
                    .frame(width: tileSize, height: tileSize)
            }
        }
        .frame(width: tileSize, height: tileSize)
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(day, inSameDayAs: Date())
    }
    
    private var activityBackgroundColor: Color {
        if isToday {
            return Color(hex: "#848484")
        } else if activities.isEmpty {
            return figmaCalendarDayIcon
        } else {
            return Color.white
        }
    }
    
    private func activityEmoji(for activity: CalendarActivityDTO) -> some View {
        Group {
            if let icon = activity.icon, !icon.isEmpty {
                Text(icon)
            } else {
                Text("⭐️")
            }
        }
    }
}


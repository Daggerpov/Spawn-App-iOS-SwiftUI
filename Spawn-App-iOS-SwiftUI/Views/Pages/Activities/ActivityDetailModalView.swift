import SwiftUI

// MARK: - Activity Detail Modal View matching Figma design
struct ActivityDetailModalView: View {
    let activity: FullFeedActivityDTO
    let activityColor: Color
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var showAttendees: Bool = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack {
                // Handle bar
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 50, height: 4)
                    .padding(.top, 12)
                
                Spacer()
                
                // Main activity card
                VStack(alignment: .leading, spacing: 16) {
                    // Header with back and menu buttons
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .opacity(0) // Hidden for now
                    }
                    
                    // Activity title and time
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activity.title ?? "Sample Activity")
                            .font(.custom("Onest", size: 28).weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(formatActivityTime())
                            .font(.custom("Onest", size: 16).weight(.semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Status and participants row
                    HStack(spacing: 24) {
                        // Status button
                        HStack(spacing: 8) {
                            Text(getActivityStatus())
                                .font(.custom("Onest", size: 17).weight(.semibold))
                                .foregroundColor(universalAccentColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.white)
                        .cornerRadius(12)
                        .opacity(getStatusOpacity())
                        
                        // Participants
                        Button(action: {
                            showAttendees = true
                        }) {
                            participantsView
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Map placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 155)
                        .overlay(
                            Text("Map View")
                                .foregroundColor(.white.opacity(0.7))
                        )
                    
                    // Location info
                    if let location = activity.location {
                        locationInfoView(location: location)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [activityColor, activityColor.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .padding(.horizontal, 25)
                
                Spacer()
                
                // Home indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 134, height: 5)
                    .padding(.bottom, 8)
            }
        }
        .background(Color.clear)
        .navigationBarHidden(true)
        .sheet(isPresented: $showAttendees) {
            AttendeeListView(
                activity: activity,
                activityColor: activityColor,
                onDismiss: {
                    showAttendees = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var participantsView: some View {
        HStack(spacing: -10) {
            // Show first few participant avatars
            if let participants = activity.participantUsers {
                ForEach(Array(participants.prefix(3).enumerated()), id: \.offset) { index, participant in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text(String(participant.name?.prefix(1) ?? "U"))
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        )
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                }
                
                // Show +count if more participants
                if participants.count > 3 {
                    Circle()
                        .fill(.white)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text("+\(participants.count - 3)")
                                .foregroundColor(universalAccentColor)
                                .font(.system(size: 15, weight: .bold))
                        )
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                }
            }
        }
    }
    
    private func locationInfoView(location: Location) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.custom("Onest", size: 16).weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("2km away")
                        .font(.custom("Onest", size: 13).weight(.medium))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "location.north.line")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(universalAccentColor)
                
                Text("Get Directions")
                    .font(.custom("Onest", size: 13).weight(.semibold))
                    .foregroundColor(universalAccentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white)
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func formatActivityTime() -> String {
        guard let startTime = activity.startTime else {
            return "Time TBD"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a • MMMM d"
        let now = Date()
        
        // Check if activity has started
        let hasStarted = now >= startTime
        
        if let endTime = activity.endTime {
            let hasEnded = now >= endTime
            let isSameDay = Calendar.current.isDate(startTime, inSameDayAs: endTime)
            
            if hasEnded {
                // Activity has completely ended
                let endFormatter = DateFormatter()
                endFormatter.dateFormat = "h:mm a • MMMM d"
                return "Ended at \(endFormatter.string(from: endTime))"
            } else if hasStarted {
                // Activity is currently happening
                if isSameDay {
                    let startFormatter = DateFormatter()
                    startFormatter.dateFormat = "h:mm a"
                    let endFormatter = DateFormatter()
                    endFormatter.dateFormat = "h:mm a • MMMM d"
                    return "Started at \(startFormatter.string(from: startTime)) • Ends at \(endFormatter.string(from: endTime))"
                } else {
                    return "Started at \(formatter.string(from: startTime))"
                }
            } else {
                // Activity hasn't started yet
                if isSameDay {
                    let startFormatter = DateFormatter()
                    startFormatter.dateFormat = "h:mm"
                    let endFormatter = DateFormatter()
                    endFormatter.dateFormat = "h:mm a • MMMM d"
                    return "\(startFormatter.string(from: startTime)) - \(endFormatter.string(from: endTime))"
                } else {
                    return "Starts at \(formatter.string(from: startTime))"
                }
            }
        } else {
            // No end time specified
            if hasStarted {
                return "Started at \(formatter.string(from: startTime))"
            } else {
                return "Starts at \(formatter.string(from: startTime))"
            }
        }
    }
    
    private func getActivityStatus() -> String {
        guard let startTime = activity.startTime else {
            return "Scheduled"
        }
        
        let now = Date()
        let hasStarted = now >= startTime
        
        if let endTime = activity.endTime {
            let hasEnded = now >= endTime
            
            if hasEnded {
                return "Ended"
            } else if hasStarted {
                return "Happening Now"
            } else {
                return "Upcoming"
            }
        } else {
            // No end time specified
            if hasStarted {
                return "Started"
            } else {
                return "Upcoming"
            }
        }
    }
    
    private func getStatusOpacity() -> Double {
        return getActivityStatus() == "Event Passed" ? 0.4 : 1.0
    }
} 

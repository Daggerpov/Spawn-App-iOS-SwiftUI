//
//  ActivityCardView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//

import SwiftUI

struct ActivityCardView: View {
    var activity: FullFeedEventDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    // Activity type (title)
                    HStack(spacing: 0) {
                        Text(activity.category == .foodAndDrink ? "Food" : (activity.title ?? "Activity"))
                            .font(.onestBold(size: 36))
                            .foregroundColor(.white)
                        Text(" by ")
                            .font(.onestRegular(size: 22))
                            .foregroundColor(.white.opacity(0.85))
                        Text("@\(activity.creatorUser.username)")
                            .font(.onestSemiBold(size: 22))
                            .foregroundColor(.white)
                    }
                    // Time range and countdown
                    HStack {
                        if let start = activity.startTime, let end = activity.endTime {
                            Text("\(formattedTime(start)) - \(formattedTime(end))")
                                .font(.onestRegular(size: 24))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Text(" • ")
                            .font(.onestRegular(size: 24))
                            .foregroundColor(.white.opacity(0.85))
                        Text("In \(timeUntil(activity.startTime))")
                            .font(.onestRegular(size: 24))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                Spacer()
                ParticipantsImagesView(event: activity)
            }
            // Location row
            ZStack(alignment: .trailing) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white)
                    Text(activity.location?.name ?? "7386 Name Street")
                        .font(.onestSemiBold(size: 22))
                        .foregroundColor(.white)
                    Text("• \(distanceString()) away")
                        .font(.onestSemiBold(size: 22))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
                .background(Color.white.opacity(0.18))
                .cornerRadius(40)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.48, green: 0.60, blue: 1.0))
        )
    }
    
    // MARK: - Helpers
    func formattedTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm" // e.g. 6:00
        return formatter.string(from: date)
    }
    
    func timeUntil(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "Started" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(minutes) min\(minutes > 1 ? "s" : "")"
        }
    }
    
    func distanceString() -> String {
        // TODO: Replace with real distance calculation if available
        return "2km"
    }
}

#if DEBUG
struct ActivityCardView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityCardView(activity: FullFeedEventDTO.mockDinnerEvent)
            .padding()
            .background(Color.gray.opacity(0.2))
    }
}
#endif

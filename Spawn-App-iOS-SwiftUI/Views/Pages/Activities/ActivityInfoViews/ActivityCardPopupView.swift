//
//  ActivityCardPopupView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/18/25.
//

import SwiftUI

struct ActivityCardPopupView: View {
    var activity: FullFeedActivityDTO
    var color: Color
    var userId: UUID
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar: Drag indicator, expand/collapse, menu
            HStack {
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                Spacer()
                Button(action: {/* Expand/Collapse */}) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 8)
                Button(action: {/* Menu */}) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Activity Title & Time
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.onestSemiBold(size: 26))
                    .foregroundColor(.white)
                Text("In X hours • 6 - 7:30pm") // TODO: Format time
                    .font(.onestRegular(size: 15))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Action Button & Participants
            HStack {
                Button(action: {/* Spawn In! */}) {
                    Text("Spawn In!")
                        .font(.onestSemiBold(size: 17))
                        .foregroundColor(color)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(22)
                }
                Spacer()
                // Participants Avatars (placeholder)
                HStack(spacing: -10) {
                    ForEach(0..<3) { i in
                        Circle().fill(Color.gray).frame(width: 32, height: 32)
                    }
                    Circle().fill(Color.white.opacity(0.7)).frame(width: 32, height: 32).overlay(
                        Text("+4").font(.onestSemiBold(size: 15)).foregroundColor(color)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Map Placeholder
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.2))
                .frame(height: 120)
                .overlay(Text("[Map goes here]").foregroundColor(.white.opacity(0.7)))
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Location Row
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.white)
                Text("7386 Name St... • 2km away") // TODO: Use real data
                    .foregroundColor(.white)
                    .font(.onestRegular(size: 13))
                Spacer()
                Button(action: {/* View on Map */}) {
                    Text("View on Map")
                        .font(.onestSemiBold(size: 14))
                        .foregroundColor(color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Description & Comments
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle().fill(Color.gray).frame(width: 28, height: 28)
                    Text("@haley_wong") // TODO: Use real username
                        .font(.onestMedium(size: 14))
                        .foregroundColor(.white)
                }
                Text("Come grab some dinner with us at Chipotle! Might go study at the library afterwards.") // TODO: Use real description
                    .font(.onestRegular(size: 14))
                    .foregroundColor(.white.opacity(0.95))
                Button(action: {/* View all comments */}) {
                    Text("View all comments")
                        .font(.onestRegular(size: 13))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("@daniel_lee I can come after my lecture finishes")
                        .font(.onestRegular(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                    Text("@d_agapov down!")
                        .font(.onestRegular(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding()
            .background(Color.white.opacity(0.13))
            .cornerRadius(14)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Timestamp
            Text("Posted 7 hours ago") // TODO: Use real timestamp
                .font(.onestRegular(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal)
                .padding(.bottom, 16)
        }
        .background(color)
        .cornerRadius(32)
        .padding(.top, 16)
        .padding(.horizontal, 8)
    }
}

#if DEBUG
struct ActivityCardPopupView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock data for preview
        let mockActivity = FullFeedActivityDTO.mockDinnerActivity // Replace with your mock or sample activity
        let mockColor = Color(red: 0.48, green: 0.60, blue: 1.0)
        let mockUserId = UUID()
        ActivityCardPopupView(activity: mockActivity, color: mockColor, userId: mockUserId)
            .background(Color.gray.opacity(0.2))
            .previewLayout(.sizeThatFits)
    }
}
#endif

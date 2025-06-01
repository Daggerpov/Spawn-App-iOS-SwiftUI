//
//  EventCardPopupView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/18/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct EventCardPopupView: View {
    var event: FullFeedEventDTO
    var color: Color
    var userId: UUID
    @StateObject private var viewModel: EventDescriptionViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(event: FullFeedEventDTO, color: Color, userId: UUID) {
        self.event = event
        self.color = color
        self.userId = userId
        _viewModel = StateObject(wrappedValue: EventDescriptionViewModel(
            apiService: MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService(),
            event: event,
            users: event.participantUsers,
            senderUserId: userId
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar: Drag indicator, expand/collapse, menu
            HStack {
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Event Title & Time
            VStack(alignment: .leading, spacing: 4) {
                if let title = event.title {
                    Text(title)
                        .font(.onestSemiBold(size: 26))
                        .foregroundColor(.white)
                }
                Text(EventInfoViewModel(event: event, eventInfoType: .time).eventInfoDisplayString)
                    .font(.onestRegular(size: 15))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Action Button & Participants
            HStack {
                Button(action: {
                    Task {
                        await viewModel.toggleParticipation()
                    }
                }) {
                    Text(viewModel.isParticipating ? "Spawned In!" : "Spawn In!")
                        .font(.onestSemiBold(size: 17))
                        .foregroundColor(color)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(22)
                }
                Spacer()
                // Participants Avatars
                if let participants = event.participantUsers {
                    HStack(spacing: -10) {
                        ForEach(participants.prefix(3)) { user in
                            if let profilePicture = user.profilePicture {
                                AsyncImage(url: URL(string: profilePicture)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle().fill(Color.gray).frame(width: 32, height: 32)
                                }
                            } else {
                                Circle().fill(Color.gray).frame(width: 32, height: 32)
                            }
                        }
                        if participants.count > 3 {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("+\(participants.count - 3)")
                                        .font(.onestSemiBold(size: 15))
                                        .foregroundColor(color)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Map Placeholder
            if let location = event.location {
                MapSnapshotView(
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                )
                .frame(height: 120)
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Location Row
            if let location = event.location {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white)
                    Text(location.name)
                        .foregroundColor(.white)
                        .font(.onestRegular(size: 13))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Description & Comments
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let profilePicture = event.creatorUser.profilePicture {
                        AsyncImage(url: URL(string: profilePicture)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle().fill(Color.gray).frame(width: 28, height: 28)
                        }
                    } else {
                        Circle().fill(Color.gray).frame(width: 28, height: 28)
                    }
                    Text("@\(event.creatorUser.username)")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(.white)
                }
                if let note = event.note {
                    Text(note)
                        .font(.onestRegular(size: 14))
                        .foregroundColor(.white.opacity(0.95))
                }
                if let chatMessages = event.chatMessages, !chatMessages.isEmpty {
                    Button(action: {/* View all comments */}) {
                        Text("View all comments")
                            .font(.onestRegular(size: 13))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(chatMessages.prefix(2)) { message in
                            Text("@\(message.senderUser.username) \(message.content)")
                                .font(.onestRegular(size: 13))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.13))
            .cornerRadius(14)
            .padding(.horizontal)
            .padding(.bottom, 8)

			// TODO DANIEL: make real createdAt property on event to show here, in the back-end and in DTOs.

            // Timestamp
			Text(FormatterService.shared.format(Date.now.advanced(by: -3600)))
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

// MapSnapshotView to show a static map image
struct MapSnapshotView: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: UIScreen.main.bounds.width - 32, height: 120)
        options.showsBuildings = true
        
        return MapSnapshotterView(options: options, coordinate: coordinate)
    }
}

struct MapSnapshotterView: View {
    let options: MKMapSnapshotter.Options
    let coordinate: CLLocationCoordinate2D
    @State private var snapshot: UIImage?
    
    var body: some View {
        Group {
            if let snapshot = snapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .scaledToFill()
                    .overlay(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    )
            } else {
                ProgressView()
            }
        }
        .onAppear {
            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start(with: .main) { snapshot, error in
                if let error = error {
                    print("Failed to generate map snapshot: \(error)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("No snapshot returned")
                    return
                }
                
                let image = UIGraphicsImageRenderer(size: snapshot.image.size).image { _ in
                    snapshot.image.draw(at: .zero)
                    
                    let pinView = UIImage(systemName: "mappin.circle.fill")?
                        .withTintColor(.red)
                    let pinPoint = snapshot.point(for: coordinate)
                    let pinRect = CGRect(
                        x: pinPoint.x - 8,
                        y: pinPoint.y - 8,
                        width: 16,
                        height: 16
                    )
                    pinView?.draw(in: pinRect)
                }
                self.snapshot = image
            }
        }
    }
}

#if DEBUG
struct EventCardPopupView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock data for preview
        let mockEvent = FullFeedEventDTO.mockDinnerEvent // Replace with your mock or sample event
        let mockColor = Color(red: 0.48, green: 0.60, blue: 1.0)
        let mockUserId = UUID()
        EventCardPopupView(event: mockEvent, color: mockColor, userId: mockUserId)
            .background(Color.gray.opacity(0.2))
            .previewLayout(.sizeThatFits)
    }
}
#endif

//
//  ActivityCardPopupView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/18/25.
//
import SwiftUI
import MapKit

struct ActivityCardPopupView: View {
    
    private var viewModel: ActivityInfoViewModel
    private var mapViewModel: MapViewModel
    @ObservedObject private var cardViewModel: ActivityCardViewModel
    var activity: FullFeedActivityDTO
    var activityColor: Color
    
    
    init(activity: FullFeedActivityDTO, activityColor: Color) {
        self.activity = activity
        viewModel = ActivityInfoViewModel(activity: activity)
        mapViewModel = MapViewModel(activity: activity)
        self.cardViewModel = ActivityCardViewModel(apiService: MockAPIService.isMocking ? MockAPIService(userId: UUID()) : APIService(), userId: UserAuthViewModel.shared.spawnUser!.id, activity: activity)
        self.activityColor = activityColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Main card content
            VStack(alignment: .leading, spacing: 16) {
                // Header with arrow and title
                HStack {
//                    Button(action: {}) {
//                        Image(systemName: "arrow.up.left.and.arrow.down.right")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
                    
                    Spacer()
                }
                
                // Event title and time
                titleAndTime
                
                // Spawn In button and attendees
                ParticipationButtonView(activity: activity, cardViewModel: cardViewModel)
                
                // Map view
                map
                
                // Location details
                directionRow
                
                // Chat section
                chatroom
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(activityColor.opacity(0.97))
        .cornerRadius(20)
        .shadow(radius: 20)
        .ignoresSafeArea(.container, edges: .bottom) // Extend into safe area at bottom
    }
}

struct MapHelper: Identifiable {
    var lat: Double
    var lon: Double
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion
    
    init(activity: FullFeedActivityDTO) {
        if let location = activity.location {
            lat = location.latitude
            lon = location.longitude
        } else { // TODO: something more robust
            lat = 0
            lon = 0
        }
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
}

extension ActivityCardPopupView {
    var titleAndTime: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.title ?? (activity.creatorUser.name ?? activity.creatorUser.username) + "'s activity")
                .font(.onestSemiBold(size: 32))
                .foregroundColor(.white)
            Text("In 2 hours • " + viewModel.getDisplayString(activityInfoType: .time))
                .font(.onestSemiBold(size: 15))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    var spawnInRow: some View {
        HStack {
            Button(action: {}) {
                HStack {
                    Image(systemName: "star.circle")
                        .foregroundColor(figmaSoftBlue)
                        .fontWeight(.bold)
                    Text("Spawn In!")
                        .font(.onestMedium(size: 18))
                        .foregroundColor(figmaSoftBlue)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
            }
            Spacer()
            ParticipantsImagesView(activity: activity)
        }
    }
    
    var map: some View {
        Map(coordinateRegion: mapViewModel.$region, annotationItems: [mapViewModel]) { pin in
            MapAnnotation(coordinate: pin.coordinate) {
                Image(systemName: "mappin")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
        .frame(height: 175)
        .cornerRadius(12)
    }
    
    var directionRow: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.white)
                .font(.system(size: 24))
                .padding(.leading, 8)
            VStack(alignment: .leading) {
                HStack {
                    Text(viewModel.getDisplayString(activityInfoType: .location))
                        .foregroundColor(.white)
                        .font(.onestSemiBold(size: 15))
                }
                Text(viewModel.getDisplayString(activityInfoType: .distance) + " away")
                    .foregroundColor(.white)
                    .font(.onestRegular(size: 14))
            }
            .padding(.vertical, 12)
            
            Spacer()
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "arrow.trianglehead.turn.up.right.diamond")
                        .fontWeight(.bold)
                        .font(.system(size: 14))
                    Text("Get Directions")
                        .font(.onestMedium(size: 13))
                }
                .foregroundColor(figmaSoftBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding(.vertical, 10)
            .padding(.trailing, 9)
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
    
    var chatroom: some View {
        HStack {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    )
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    )
                    .offset(x: -15)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Chatroom")
                    .foregroundColor(.white)
                    .font(.onestMedium(size: 18))
                Text("Haley: Come grab dinner with us...")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.onestRegular(size: 15))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ParticipationButtonView: View {
    private var activity: FullFeedActivityDTO
    @ObservedObject private var cardViewModel: ActivityCardViewModel
    
    init(activity: FullFeedActivityDTO, cardViewModel: ActivityCardViewModel) {
        self.activity = activity
        self.cardViewModel = cardViewModel
    }
    private var participationText: String {
            cardViewModel.isParticipating ? "Going" : "Spawn In!"
    }
    
    private var participationColor: Color {
        cardViewModel.isParticipating ? figmaGreen : figmaSoftBlue
    }
    
    private var participationIcon: String {
        cardViewModel.isParticipating ? "checkmark.circle" : "star.circle"
    }
    
    var body: some View {
        HStack {
            Button(action: {
                Task {
                    await cardViewModel.toggleParticipation()
                }
            }) {
                HStack {
                    Image(systemName: participationIcon)
                        .foregroundColor(participationColor)
                        .fontWeight(.bold)
                    Text(participationText)
                        .font(.onestMedium(size: 18))
                        .foregroundColor(participationColor)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
            }
            Spacer()
            ParticipantsImagesView(activity: activity)
        }
    }
}

struct ActivityCardPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityCardPopupView(activity: FullFeedActivityDTO.mockDinnerActivity, activityColor: figmaSoftBlue)
            .preferredColorScheme(.light)
    }
}

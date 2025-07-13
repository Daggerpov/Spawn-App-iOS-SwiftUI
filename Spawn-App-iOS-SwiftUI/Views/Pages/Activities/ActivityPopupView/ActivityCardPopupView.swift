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
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var cardViewModel: ActivityCardViewModel
    @StateObject private var locationManager = LocationManager()
    @ObservedObject var activity: FullFeedActivityDTO
    var activityColor: Color
    @State private var region: MKCoordinateRegion
    
    
    init(activity: FullFeedActivityDTO, activityColor: Color) {
        self.activity = activity
        viewModel = ActivityInfoViewModel(activity: activity, locationManager: LocationManager())
        let mapVM = MapViewModel(activity: activity)
        _mapViewModel = StateObject(wrappedValue: mapVM)
        self._cardViewModel = StateObject(wrappedValue: ActivityCardViewModel(apiService: MockAPIService.isMocking ? MockAPIService(userId: UUID()) : APIService(), userId: UserAuthViewModel.shared.spawnUser!.id, activity: activity))
        self.activityColor = activityColor
        _region = State(initialValue: mapVM.initialRegion)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 2.5)
                                            .fill(universalBackgroundColor.opacity(0.8))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Main card content
                VStack(alignment: .leading, spacing: 16) {
                    // Header with arrow and title
                    HStack {
                        Spacer()
                    }
                    
                    // Event title and time
                    titleAndTime
                    
                    // Spawn In button and attendees
                    ParticipationButtonView(activity: activity, cardViewModel: cardViewModel)
                    
                    // Map view
                    Map(coordinateRegion: $region, annotationItems: [mapViewModel]) { pin in
                        MapAnnotation(coordinate: pin.coordinate) {
                            Image(systemName: "mappin")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                    }
                    .frame(height: 175)
                    .cornerRadius(12)
                    
                    // Location details
                    directionRow
                    
                    // Chat section
                    ChatroomButtonView(activity: activity, activityColor: activityColor)
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
            Text(FormatterService.shared.timeUntil(activity.startTime) + " • " + viewModel.getDisplayString(activityInfoType: .time))
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
                .background(universalBackgroundColor)
                .cornerRadius(12)
            }
            Spacer()
            ParticipantsImagesView(activity: activity)
        }
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
            
            Button(action: {
                // Create source map item from user's current location
                let sourceMapItem = MKMapItem.forCurrentLocation()
                
                // Create destination map item from activity location
                let destinationMapItem = mapViewModel.mapItem
                
                // Open Maps with directions from current location to activity location
                MKMapItem.openMaps(
                    with: [sourceMapItem, destinationMapItem],
                    launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault,
                        MKLaunchOptionsShowsTrafficKey: true
                    ]
                )
            }) {
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
                .background(.white)
                .cornerRadius(12)
            }
            .padding(.vertical, 10)
            .padding(.trailing, 9)
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ParticipationButtonView: View {
    @ObservedObject private var activity: FullFeedActivityDTO
    @ObservedObject private var cardViewModel: ActivityCardViewModel
    
    // Animation states for 3D effect
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
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
                // Haptic feedback
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
                
                // Execute action with slight delay for animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Task {
                        await cardViewModel.toggleParticipation()
                    }
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
                .background(.white)
                .cornerRadius(12)
                .scaleEffect(scale)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: isPressed ? 2 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
            }
            .buttonStyle(PlainButtonStyle())
            .animation(.easeInOut(duration: 0.15), value: scale)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
                scale = pressing ? 0.95 : 1.0
                
                // Additional haptic feedback for press down
                if pressing {
                    let selectionGenerator = UISelectionFeedbackGenerator()
                    selectionGenerator.selectionChanged()
                }
            }, perform: {})
            
            Spacer()
            ParticipantsImagesView(activity: activity)
        }
    }
}

struct ChatroomButtonView: View {
    var user: BaseUserDTO = UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov
    let activityColor: Color
    @ObservedObject var activity: FullFeedActivityDTO
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingChatroom = false
    
    init(activity: FullFeedActivityDTO, activityColor: Color) {
        self.activity = activity
        self.activityColor = activityColor
        viewModel = ChatViewModel(senderUserId: user.id, activity: activity)
    }
    
    
    var body: some View {
        Button(action: {
            showingChatroom = true
        }) {
            HStack {
                if viewModel.chats.isEmpty {
                    Image("EmptyDottedCircle")
                } else {
                    profilePictures
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chatroom")
                        .foregroundColor(.white)
                        .font(.onestMedium(size: 18))
                    if viewModel.chats.isEmpty {
                        Text("Be the first to send a message!")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.onestRegular(size: 15))
                    } else if !viewModel.chats.isEmpty {
                        let sender = viewModel.chats[0].senderUser
                        Text((sender == user ? "You:" : sender.name ?? sender.username) + " " + viewModel.chats[0].content)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.onestRegular(size: 15))
                    }
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingChatroom) {
            ChatroomView(activity: activity, backgroundColor: activityColor)
        }
    }
    
    var profilePictures: some View {
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
    }
}

struct ActivityCardPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityCardPopupView(activity: FullFeedActivityDTO.mockDinnerActivity, activityColor: figmaSoftBlue)
            
    }
}

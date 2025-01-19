//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import MapKit
import SwiftUI

struct MapView: View {
	@EnvironmentObject var user: ObservableUser

	@StateObject private var viewModel: FeedViewModel

	@State private var region = MKCoordinateRegion(
		center: CLLocationCoordinate2D(
			latitude: 49.26676252116466, longitude: -123.25000960684207),  // Default to UBC AMS Nest
		span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
	)
	let mockTags: [FriendTag] = FriendTag.mockTags

	// MARK - Event Description State Vars
	@State private var showingEventDescriptionPopup: Bool = false
	@State private var eventInPopup: Event?
	@State private var colorInPopup: Color?

	@State private var showingEventCreationPopup: Bool = false

	// for pop-ups:
	@State private var descriptionOffset: CGFloat = 1000
	@State private var creationOffset: CGFloat = 1000
	// ------------

	init(user: User) {
		_viewModel = StateObject(wrappedValue: FeedViewModel(apiService: MockAPIService.isMocking ? MockAPIService() : APIService(), user: user))
	}

	var body: some View {
		ZStack{
			ZStack {
				Map(
					coordinateRegion: $region,
					annotationItems: viewModel.events
				) { mockEvent in
					MapAnnotation(
						coordinate: CLLocationCoordinate2D(
							latitude: mockEvent.location?.latitude ?? 0,
							longitude: mockEvent.location?.longitude ?? 0
						), anchorPoint: CGPoint(x: 0.5, y: 1.0)
					) {
						Button(action: {
							eventInPopup = mockEvent
							colorInPopup = eventColors.randomElement()
							showingEventDescriptionPopup = true
						}) {
							VStack(spacing: -8) {
								ZStack {
									Image(systemName: "mappin.circle.fill")
										.resizable()
										.scaledToFit()
										.frame(width: 60, height: 60)
										.foregroundColor(universalAccentColor)

									let creatorOne: User = mockEvent.creator ?? User.danielAgapov

									if let creatorPfp = creatorOne
										.profilePicture
									{
										Image(creatorPfp)
											.ProfileImageModifier(
												imageType: .mapView)
									}
								}
								Triangle()
									.fill(universalAccentColor)
									.frame(width: 40, height: 20)
							}
						}
					}
				}
				.ignoresSafeArea()
				VStack {
					VStack {
						TagsScrollView(tags: viewModel.tags)
					}
					.padding(.horizontal)
					.padding(.top, 20)
					Spacer()
					HStack(spacing: 35) {
						BottomNavButtonView(buttonType: .feed, source: .map)
						Spacer()
						EventCreationButtonView(
							showingEventCreationPopup: $showingEventCreationPopup
						)
						Spacer()
						BottomNavButtonView(buttonType: .friends, source: .map)
					}
					.padding(32)
				}
				.padding(.top, 50)
				.dimmedBackground(
					isActive: showingEventDescriptionPopup
					|| showingEventCreationPopup
				)
			}

			.ignoresSafeArea()
			.onAppear {
				adjustRegionForEvents()
				Task{
					await viewModel.fetchEventsForUser()
					await viewModel.fetchTagsForUser()
				}
			}
			if showingEventDescriptionPopup {
				EventDescriptionPopupView(
					eventInPopup: eventInPopup,
					colorInPopup: colorInPopup,
					closeDescription: {
						closeDescription()
					},
					offset: $descriptionOffset
				)
			}
			if showingEventCreationPopup {
				EventCreationPopupView(
					user: user.user,
					closeCreation: {
						closeCreation()
					},
					offset: $creationOffset
				)
			}
		}
	}
	private func adjustRegionForEvents() {
		guard !viewModel.events.isEmpty else { return }

		let latitudes = viewModel.events.compactMap { $0.location?.latitude }
		let longitudes = viewModel.events.compactMap { $0.location?.longitude }

		guard let minLatitude = latitudes.min(),
			  let maxLatitude = latitudes.max(),
			  let minLongitude = longitudes.min(),
			  let maxLongitude = longitudes.max() else { return }

		let centerLatitude = (minLatitude + maxLatitude) / 2
		let centerLongitude = (minLongitude + maxLongitude) / 2
		let latitudeDelta = (maxLatitude - minLatitude) * 1.5 // Add padding
		let longitudeDelta = (maxLongitude - minLongitude) * 1.5 // Add padding

		region = MKCoordinateRegion(
			center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
			span: MKCoordinateSpan(latitudeDelta: max(latitudeDelta, 0.01), longitudeDelta: max(longitudeDelta, 0.01))
		)
	}

	func closeDescription() {
		withAnimation(.spring()) {
			descriptionOffset = 1000
			showingEventDescriptionPopup = false
		}
	}

	func closeCreation() {
		withAnimation(.spring()) {
			creationOffset = 1000
			showingEventCreationPopup = false
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @StateObject var observableUser: ObservableUser =
		ObservableUser(
			user: .danielLee
		)
	MapView(user: observableUser.user)
		.environmentObject(observableUser)
}

struct Triangle: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
		path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
		path.closeSubpath()
		return path
	}
}

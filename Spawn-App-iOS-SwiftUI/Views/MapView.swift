//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import MapKit
import PopupView
import SwiftUI

struct MapView: View {
	@EnvironmentObject var user: ObservableUser

	@StateObject var viewModel: FeedViewModel = FeedViewModel(
		events: Event.mockEvents)
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

	var body: some View {
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

								if let creatorPfp = mockEvent.creator
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
					TagsScrollView(tags: mockTags)
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
		}

		.ignoresSafeArea()
		.onAppear {
			adjustRegionForEvents()
		}
		.popup(isPresented: $showingEventDescriptionPopup) {
			if let event = eventInPopup, let color = colorInPopup {
				EventDescriptionView(
					event: event,
					users: User.mockUsers,
					color: color
				)
			}
		} customize: {
			$0
				.type(
					.floater(
						verticalPadding: 20,
						horizontalPadding: 20,
						useSafeAreaInset: false
					))
			// TODO: read up on the documentation: https://github.com/exyte/popupview
			// so that the description view is dismissed upon clicking outside
		}
		.popup(isPresented: $showingEventCreationPopup) {
			EventCreationView(creatingUser: user.user)
		} customize: {
			$0
				.type(.floater(
					verticalPadding: 20,
					horizontalPadding: 20,
					useSafeAreaInset: false
				))
			// TODO: read up on the documentation: https://github.com/exyte/popupview
			// so that the description view is dismissed upon clicking outside
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
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @StateObject var observableUser: ObservableUser =
		ObservableUser(
			user: .danielLee
		)
	MapView()
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

import MapKit
//
//  ActivityCardPopupView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/18/25.
//
import SwiftUI

struct ActivityCardPopupView: View {
	@State private var viewModel: ActivityInfoViewModel
	@State private var mapViewModel: MapViewModel
	@State private var cardViewModel: ActivityCardViewModel
	@ObservedObject private var locationManager = LocationManager.shared
	@ObservedObject var activity: FullFeedActivityDTO
	var activityColor: Color
	@State private var region: MKCoordinateRegion
	@Binding var isExpanded: Bool

	// Optional binding to control tab selection for current user navigation
	@Binding var selectedTab: TabType?

	// Flag to determine if opened from map view
	let fromMapView: Bool

	// Callback to dismiss the drawer
	let onDismiss: () -> Void

	// Callback to minimize the drawer
	let onMinimize: () -> Void

	// State for activity reporting
	@State private var showActivityMenu: Bool = false
	@State private var showReportDialog: Bool = false
	@State private var showingChatroom = false  // Add this state for navigation
	@State private var showingParticipants = false  // Add this state for participants navigation

	init(
		activity: FullFeedActivityDTO,
		activityColor: Color,
		isExpanded: Binding<Bool>,
		selectedTab: Binding<TabType?> = .constant(nil),
		fromMapView: Bool = false,
		onDismiss: @escaping () -> Void = {},
		onMinimize: @escaping () -> Void = {}
	) {
		// Get the most up-to-date activity from cache to ensure correct participation status
		let cachedActivity = AppCache.shared.getActivityById(activity.id) ?? activity

		self.activity = cachedActivity
		self._viewModel = State(
			wrappedValue: ActivityInfoViewModel(
				activity: cachedActivity,
				locationManager: LocationManager.shared
			)
		)
		let mapVM = MapViewModel(activity: cachedActivity)
		_mapViewModel = State(wrappedValue: mapVM)
		self._cardViewModel = State(
			wrappedValue: ActivityCardViewModel(
				userId: UserAuthViewModel.shared.spawnUser?.id ?? BaseUserDTO.danielAgapov.id,
				activity: cachedActivity
			)
		)
		self.activityColor = activityColor
		_region = State(initialValue: mapVM.initialRegion)
		self._isExpanded = isExpanded
		self._selectedTab = selectedTab
		self.fromMapView = fromMapView
		self.onDismiss = onDismiss
		self.onMinimize = onMinimize
	}

	var body: some View {
		VStack(spacing: 0) {
			// Handle bar - only show when not expanded
			if !isExpanded {
				RoundedRectangle(cornerRadius: 2.5)
					.fill(Color.white.opacity(0.6))
					.frame(width: 50, height: 4)
					.padding(.top, 12)  // Consistent padding for handle bar
			} else {
				// Add top padding when expanded to match Figma design (~70px from top)
				// This ensures the X button is positioned lower, matching the design
				Spacer()
					.frame(height: 60)  // Consistent for all expanded popups
			}

			// Conditional content based on navigation state
			if showingChatroom {
				// Chatroom content
				ChatroomContentView(
					activity: activity,
					backgroundColor: activityColor,
					isExpanded: isExpanded,
					fromMapView: fromMapView,
					onBack: {
						withAnimation(.easeInOut(duration: 0.3)) {
							showingChatroom = false
						}
					}
				)
			} else if showingParticipants {
				// Participants content
				ParticipantsContentView(
					activity: activity,
					backgroundColor: activityColor,
					isExpanded: isExpanded,
					onBack: {
						withAnimation(.easeInOut(duration: 0.3)) {
							showingParticipants = false
						}
					},
					selectedTab: $selectedTab,
					onDismiss: onDismiss
				)
			} else {
				// Main card content
				mainCardContent
			}
		}
		.background(activityColor.opacity(0.80).blendMode(.multiply))
		.cornerRadius(isExpanded ? 0 : 20)
		.shadow(radius: isExpanded ? 0 : 20)
		.ignoresSafeArea(
			(showingChatroom || showingParticipants) && isExpanded
				? .all : .container,
			edges: (showingChatroom || showingParticipants) && isExpanded
				? .all : .bottom
		)  // Fill entire screen when chatroom/participants are maximized
		.frame(maxWidth: .infinity, maxHeight: isExpanded ? .infinity : nil)  // Only expand to fill when expanded
		.sheet(isPresented: $showActivityMenu) {
			ActivityMenuView(
				activity: activity,
				showReportDialog: $showReportDialog
			)
			.presentationDetents([.height(200)])
			.presentationDragIndicator(.visible)
		}
		.sheet(isPresented: $showReportDialog) {
			ReportActivityDrawer(
				activity: activity,
				onReport: { reportType, description in
					Task {
						await self.reportActivity(
							reportType: reportType,
							description: description
						)
					}
				}
			)
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
		}
		.onReceive(NotificationCenter.default.publisher(for: .showChatroom)) {
			_ in
			withAnimation(.easeInOut(duration: 0.3)) {
				showingChatroom = true
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .showParticipants)) { _ in
			withAnimation(.easeInOut(duration: 0.3)) {
				showingParticipants = true
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .activityUpdated)) { notification in
			if let updatedActivity = notification.object as? FullFeedActivityDTO,
				updatedActivity.id == activity.id
			{
				print("🔄 ActivityCardPopupView: Received activity update for \(updatedActivity.title ?? "Unknown")")

				// Update all view models with the new activity data
				viewModel.updateActivity(updatedActivity)
				mapViewModel.updateActivity(updatedActivity)
				cardViewModel.updateActivity(updatedActivity)

				// Update the region for the map to reflect new location
				region = mapViewModel.initialRegion
			}
		}
	}

	private func reportActivity(reportType: ReportType, description: String)
		async
	{
		guard let currentUserId = UserAuthViewModel.shared.spawnUser?.id else {
			return
		}

		do {
			let reportingService = ReportingService()
			try await reportingService.reportActivity(
				reporterUserId: currentUserId,
				activityId: activity.id,
				reportType: reportType,
				description: description
			)
			print("Activity reported successfully")
		} catch {
			print("Error reporting activity: \(error)")
		}
	}

	var mainCardContent: some View {
		VStack(alignment: .leading, spacing: 16) {
			// Header with arrow and title
			HStack {
				Button(action: {
					if isExpanded {
						onMinimize()
					} else {
						withAnimation(.easeInOut(duration: 0.3)) {
							isExpanded = true
						}
					}
				}) {
					Image(systemName: isExpanded ? "xmark" : "arrow.up.left.and.arrow.down.right")
						.foregroundColor(.white)
						.font(.system(size: 24, weight: .regular))
				}
				.buttonStyle(PlainButtonStyle())

				Spacer()

				// Only show menu for activities not owned by current user
				if let currentUserId = UserAuthViewModel.shared.spawnUser?.id,
					currentUserId != activity.creatorUser.id
				{
					Button(action: {
						showActivityMenu = true
					}) {
						Image(systemName: "ellipsis")
							.foregroundColor(.white)
							.font(.title3)
							.padding(12)  // Increased padding for better touch targets
					}
					.buttonStyle(PlainButtonStyle())
					.allowsHitTesting(true)
					.contentShape(Circle())  // Better touch area for circular button
				}
			}
			.padding(.top, 8)  // Consistent padding matching Figma's py-[8px]

			// Event title and time
			titleAndTime

			// Spawn In button and attendees
			ParticipationButtonView(
				activity: activity,
				cardViewModel: cardViewModel,
				selectedTab: $selectedTab
			)

			// Map and location info container - always visible
			if activity.location != nil {
				if fromMapView {
					mapViewLocationSection
				} else {
					mapAndLocationView
				}
			}

			// Chat section
			ChatroomButtonView(activity: activity, activityColor: activityColor)

			// Spacer pushes content to top when expanded
			if isExpanded {
				Spacer()
			}
		}
		.padding(.horizontal, 26)
		.padding(.bottom, isExpanded ? 40 : 120)  // Less padding when minimized since content sits at bottom
	}

	var mapAndLocationView: some View {
		ZStack(alignment: .bottom) {
			// Map background
			if #available(iOS 17.0, *) {
				Map(position: .constant(.region(region))) {
					Annotation("", coordinate: mapViewModel.coordinate) {
						Image(systemName: "mappin")
							.font(.title)
							.foregroundColor(.red)
					}
				}
				.frame(height: 200)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(
							Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50)
						)
				)
				.allowsHitTesting(false)  // Disable map interaction to prevent gesture conflicts
			} else {
				Map(coordinateRegion: $region, annotationItems: [mapViewModel]) {
					pin in
					MapAnnotation(coordinate: pin.coordinate) {
						Image(systemName: "mappin")
							.font(.title)
							.foregroundColor(.red)
					}
				}
				.frame(height: 200)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(
							Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50)
						)
				)
				.allowsHitTesting(false)  // Disable map interaction to prevent gesture conflicts
			}

			// Location info overlay at bottom
			locationOverlay
		}
	}

	var locationOverlay: some View {
		HStack {
			// Location info on left
			locationInfoSection

			Spacer()

			// View in Maps button on right
			viewInMapsButton
		}
		.padding(.horizontal, 12)
		.padding(.bottom, 12)
		.zIndex(1)  // Ensure overlay is above the map
		.allowsHitTesting(true)  // Ensure the overlay can receive touches
	}

	var locationInfoSection: some View {
		HStack(spacing: 6) {
			Image(systemName: "mappin.and.ellipse")
				.font(.system(size: 14, weight: .medium))
				.foregroundColor(.white)

			// Display location and distance separately to control truncation
			HStack(spacing: 4) {
				Text(viewModel.getDisplayString(activityInfoType: .location))
					.font(Font.custom("Onest", size: 14).weight(.medium))
					.foregroundColor(.white)
					.lineLimit(1)
					.truncationMode(.tail)
					.layoutPriority(0)  // Lower priority for truncation

				if viewModel.isDistanceAvailable() {
					Text(
						"• \(viewModel.getDisplayString(activityInfoType: .distance)) away"
					)
					.font(Font.custom("Onest", size: 14).weight(.medium))
					.foregroundColor(.white)
					.lineLimit(1)
					.fixedSize(horizontal: true, vertical: false)  // Prevent truncation of distance
					.layoutPriority(1)  // Higher priority to keep this part visible
				}
			}
		}
		.padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
		.background(Color(red: 0.33, green: 0.42, blue: 0.93).opacity(0.80))
		.cornerRadius(10)
	}

	var viewInMapsButton: some View {
		HStack(spacing: 6) {
			Image(systemName: "arrow.triangle.turn.up.right.diamond")
				.font(.system(size: 12, weight: .bold))
				.foregroundColor(Color(red: 0.33, green: 0.42, blue: 0.93))

			Text("View in Maps")
				.font(.onestSemiBold(size: 14))
				.foregroundColor(Color(red: 0.33, green: 0.42, blue: 0.93))
		}
		.padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
		.background(.white)
		.cornerRadius(12)
		.overlay(
			RoundedRectangle(cornerRadius: 10)
				.stroke(Color(red: 0.95, green: 0.93, blue: 0.93), lineWidth: 1)  // border matching background
				.shadow(color: Color.black.opacity(0.25), radius: 2, x: -2, y: -2)  // dark shadow top
				.clipShape(RoundedRectangle(cornerRadius: 12))
				.shadow(color: Color.white.opacity(0.7), radius: 4, x: 4, y: 4)  // light shadow bottom
				.clipShape(RoundedRectangle(cornerRadius: 12))
		)
		.shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 4)
		.contentShape(Rectangle())  // Define the entire button area as tappable
		.simultaneousGesture(
			TapGesture()
				.onEnded { _ in
					guard let location = activity.location else { return }

					let coordinate = CLLocationCoordinate2D(
						latitude: location.latitude,
						longitude: location.longitude
					)
					let destinationMapItem = MKMapItem(
						placemark: MKPlacemark(coordinate: coordinate)
					)
					destinationMapItem.name = location.name

					let sourceMapItem = MKMapItem.forCurrentLocation()

					MKMapItem.openMaps(
						with: [sourceMapItem, destinationMapItem],
						launchOptions: [
							MKLaunchOptionsDirectionsModeKey:
								MKLaunchOptionsDirectionsModeDefault,
							MKLaunchOptionsShowsTrafficKey: true,
						]
					)
				}
		)
		.allowsHitTesting(true)
	}
}

extension ActivityCardPopupView {
	var titleAndTime: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(viewModel.getDisplayString(activityInfoType: .title))
				.font(.onestSemiBold(size: 32))
				.foregroundColor(.white)
			Text(
				FormatterService.shared.timeUntil(activity.startTime) + " • "
					+ viewModel.getDisplayString(activityInfoType: .time)
			)
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
			ParticipantsImagesView(
				activity: activity,
				selectedTab: $selectedTab,
				imageType: .participantsPopup
			)
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
					Text(
						viewModel.getDisplayString(activityInfoType: .location)
					)
					.foregroundColor(.white)
					.font(.onestSemiBold(size: 15))
				}
				if viewModel.isDistanceAvailable() {
					Text(
						"• \(viewModel.getDisplayString(activityInfoType: .distance)) away"
					)
					.foregroundColor(.white)
					.font(.onestRegular(size: 14))
				}
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
						MKLaunchOptionsDirectionsModeKey:
							MKLaunchOptionsDirectionsModeDefault,
						MKLaunchOptionsShowsTrafficKey: true,
					]
				)
			}) {
				HStack {
					Image(
						systemName: "arrow.trianglehead.turn.up.right.diamond"
					)
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
			.buttonStyle(PlainButtonStyle())
			.allowsHitTesting(true)
			.contentShape(Rectangle())
			.padding(.vertical, 10)
			.padding(.trailing, 9)
		}
		.background(Color.black.opacity(0.2))
		.cornerRadius(12)
	}

	var locationInfoView: some View {
		HStack(spacing: 8) {
			// Location info pill
			HStack(spacing: 8) {
				Image(systemName: "mappin.and.ellipse")
					.font(.system(size: 14))
					.foregroundColor(.white)
				// Display location and distance separately to control truncation
				HStack(spacing: 4) {
					Text(
						viewModel.getDisplayString(activityInfoType: .location)
					)
					.font(.custom("Onest", size: 14).weight(.medium))
					.foregroundColor(.white)
					.lineLimit(1)
					.truncationMode(.tail)
					.layoutPriority(0)  // Lower priority for truncation

					if viewModel.isDistanceAvailable() {
						Text(
							"• \(viewModel.getDisplayString(activityInfoType: .distance)) away"
						)
						.font(.custom("Onest", size: 14).weight(.medium))
						.foregroundColor(.white)
						.lineLimit(1)
						.fixedSize(horizontal: true, vertical: false)  // Prevent truncation of distance
						.layoutPriority(1)  // Higher priority to keep this part visible
					}
				}
			}
			.padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
			.background(Color(red: 0.33, green: 0.42, blue: 0.93).opacity(0.80))
			.cornerRadius(12)

			// View in Maps button
			Button(action: {
				// Create source map item from user's current location
				let sourceMapItem = MKMapItem.forCurrentLocation()

				// Create destination map item from activity location
				let destinationMapItem = mapViewModel.mapItem

				// Open Maps with directions from current location to activity location
				MKMapItem.openMaps(
					with: [sourceMapItem, destinationMapItem],
					launchOptions: [
						MKLaunchOptionsDirectionsModeKey:
							MKLaunchOptionsDirectionsModeDefault,
						MKLaunchOptionsShowsTrafficKey: true,
					]
				)
			}) {
				HStack(spacing: 6) {
					Image(systemName: "map")
						.font(.system(size: 14, weight: .bold))
						.foregroundColor(
							Color(red: 0.33, green: 0.42, blue: 0.93)
						)
					Text("View in Maps")
						.font(.custom("Onest", size: 14).weight(.semibold))
						.foregroundColor(
							Color(red: 0.33, green: 0.42, blue: 0.93)
						)
				}
				.padding(
					EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
				)
				.background(.white)
				.cornerRadius(12)
				.shadow(
					color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
					radius: 16,
					y: 4
				)
			}
		}
	}

	// Map view location section - simplified version for when opened from map
	var mapViewLocationSection: some View {
		HStack(spacing: 8) {
			HStack(spacing: 8) {
				Image("mapview_location_pin_icon")
					.resizable()
					.renderingMode(.original)
					.scaledToFit()
					.frame(width: 28, height: 28)
				VStack(alignment: .leading, spacing: 2) {
					Text(viewModel.getDisplayString(activityInfoType: .location))
						.font(Font.custom("Onest", size: 16).weight(.bold))
						.foregroundColor(.white)
						.lineLimit(1)
						.truncationMode(.tail)
					Text("\(viewModel.getDisplayString(activityInfoType: .distance)) away")
						.font(Font.custom("Onest", size: 13).weight(.medium))
						.foregroundColor(.white)
				}
			}

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
						MKLaunchOptionsDirectionsModeKey:
							MKLaunchOptionsDirectionsModeDefault,
						MKLaunchOptionsShowsTrafficKey: true,
					]
				)
			}) {
				HStack(spacing: 6) {
					Image(systemName: "arrow.trianglehead.turn.up.right.diamond")
						.font(.system(size: 14, weight: .bold))
						.foregroundColor(Color(red: 0.11, green: 0.63, blue: 0.29))
					Text("Get Directions")
						.font(Font.custom("Onest", size: 13).weight(.semibold))
						.foregroundColor(Color(red: 0.11, green: 0.63, blue: 0.29))
				}
				.padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
				.background(.white)
				.cornerRadius(12)
			}
			.buttonStyle(PlainButtonStyle())
			.allowsHitTesting(true)
			.contentShape(Rectangle())
		}
		.padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
		.frame(maxWidth: .infinity)
		.frame(height: 67)
		.background(Color(red: 0, green: 0, blue: 0).opacity(0.20))
		.cornerRadius(12)
	}
}

struct ActivityCardPopupView_Previews: PreviewProvider {
	static var previews: some View {
		ActivityCardPopupView(
			activity: FullFeedActivityDTO.mockDinnerActivity,
			activityColor: figmaSoftBlue,
			isExpanded: .constant(false),
			onDismiss: {},
			onMinimize: {}
		)

	}
}

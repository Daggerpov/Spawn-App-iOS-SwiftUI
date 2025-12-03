//
//  MapControlButtons.swift
//  Spawn-App-iOS-SwiftUI
//
//  Map control buttons for 3D toggle and location centering
//

import CoreLocation
import MapKit
import SwiftUI

struct MapControlButtons: View {
	// MARK: - Bindings
	@Binding var is3DMode: Bool
	@Binding var region: MKCoordinateRegion

	// MARK: - Properties
	@ObservedObject var locationManager: LocationManager

	// MARK: - State
	// State variables removed - using simpler button styling without press animations

	// MARK: - Body

	var body: some View {
		VStack {
			HStack {
				Spacer()
				VStack(spacing: 0) {
					// 3D mode toggle
					Button(action: {
						handleToggle3D()
					}) {
						Text("3D")
							.font(.system(size: 16, weight: .semibold))
							.foregroundColor(universalAccentColor)
							.frame(width: 44, height: 44)
							.background(universalBackgroundColor)
							.clipShape(
								UnevenRoundedRectangle(
									topLeadingRadius: 10,
									bottomLeadingRadius: 0,
									bottomTrailingRadius: 0,
									topTrailingRadius: 10
								)
							)
					}
					.buttonStyle(PlainButtonStyle())

					// Recenter to user location
					Button(action: {
						handleCenterOnUser()
					}) {
						Image(systemName: "location.fill")
							.font(.system(size: 20))
							.foregroundColor(universalAccentColor)
							.frame(width: 44, height: 44)
							.background(universalBackgroundColor)
							.clipShape(
								UnevenRoundedRectangle(
									topLeadingRadius: 0,
									bottomLeadingRadius: 10,
									bottomTrailingRadius: 10,
									topTrailingRadius: 0
								)
							)
					}
					.buttonStyle(PlainButtonStyle())
					.disabled(locationManager.userLocation == nil)
					.opacity(locationManager.userLocation == nil ? 0.5 : 1.0)
				}
				.shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
				.padding(.trailing, 16)
			}
			.padding(.top, 24)
			Spacer()
		}
	}

	// MARK: - Actions

	private func handleToggle3D() {
		hapticFeedback(.medium)
		withAnimation(.easeInOut(duration: 0.3)) {
			is3DMode.toggle()
		}
	}

	private func handleCenterOnUser() {
		guard let userLocation = locationManager.userLocation else {
			return
		}

		// Validate user location before using it
		guard
			CLLocationCoordinate2DIsValid(userLocation) && userLocation.latitude.isFinite
				&& userLocation.longitude.isFinite && !userLocation.latitude.isNaN
				&& !userLocation.longitude.isNaN
		else {
			print("⚠️ MapControlButtons: Invalid user location for recenter - \(userLocation)")
			return
		}

		let newRegion = MKCoordinateRegion(
			center: userLocation,
			span: MKCoordinateSpan(
				latitudeDelta: 0.01,
				longitudeDelta: 0.01
			)
		)

		// Validate the new region
		guard
			CLLocationCoordinate2DIsValid(newRegion.center) && newRegion.span.latitudeDelta > 0
				&& newRegion.span.longitudeDelta > 0 && newRegion.span.latitudeDelta.isFinite
				&& newRegion.span.longitudeDelta.isFinite
		else {
			print("⚠️ MapControlButtons: Invalid region for recenter")
			return
		}

		hapticFeedback(.medium)
		withAnimation(.easeInOut(duration: 0.75)) {
			region = newRegion
		}
	}

	// MARK: - Haptic Feedback

	private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
}

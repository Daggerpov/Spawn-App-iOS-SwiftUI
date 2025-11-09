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
	@State private var is3DPressed = false
	@State private var isLocationPressed = false
	
	// MARK: - Body
	
	var body: some View {
		VStack {
			HStack {
				Spacer()
				
				VStack(spacing: 12) {
					// 3D Toggle Button
					Button {
						handleToggle3D()
					} label: {
						Image(systemName: is3DMode ? "view.3d" : "view.2d")
							.font(.system(size: 18, weight: .medium))
							.foregroundColor(universalAccentColor)
							.frame(width: 44, height: 44)
							.background(universalBackgroundColor)
							.clipShape(Circle())
							.shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
							.scaleEffect(is3DPressed ? 0.9 : 1.0)
					}
					.buttonStyle(.plain)
					.simultaneousGesture(
						DragGesture(minimumDistance: 0)
							.onChanged { _ in
								if !is3DPressed {
									is3DPressed = true
									hapticFeedback(.light)
								}
							}
							.onEnded { _ in
								is3DPressed = false
							}
					)
					
					// Location Center Button
					Button {
						handleCenterOnUser()
					} label: {
						Image(systemName: "location.fill")
							.font(.system(size: 18, weight: .medium))
							.foregroundColor(universalAccentColor)
							.frame(width: 44, height: 44)
							.background(universalBackgroundColor)
							.clipShape(Circle())
							.shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
							.scaleEffect(isLocationPressed ? 0.9 : 1.0)
					}
					.buttonStyle(.plain)
					.disabled(locationManager.userLocation == nil)
					.opacity(locationManager.userLocation == nil ? 0.5 : 1.0)
					.simultaneousGesture(
						DragGesture(minimumDistance: 0)
							.onChanged { _ in
								if !isLocationPressed && locationManager.userLocation != nil {
									isLocationPressed = true
									hapticFeedback(.light)
								}
							}
							.onEnded { _ in
								isLocationPressed = false
							}
					)
				}
				.padding(.trailing, 16)
			}
			.padding(.top, 16)
			
			Spacer()
		}
		.animation(.easeInOut(duration: 0.2), value: is3DPressed)
		.animation(.easeInOut(duration: 0.2), value: isLocationPressed)
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
		
		hapticFeedback(.medium)
		withAnimation(.easeInOut(duration: 0.75)) {
			region = MKCoordinateRegion(
				center: userLocation,
				span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
			)
		}
	}
	
	// MARK: - Haptic Feedback
	
	private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
		let generator = UIImpactFeedbackGenerator(style: style)
		generator.impactOccurred()
	}
}

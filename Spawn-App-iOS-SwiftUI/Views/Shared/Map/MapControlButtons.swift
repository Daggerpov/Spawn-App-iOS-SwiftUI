//
//  MapControlButtons.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/8/25.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapControlButtons: View {
	@Binding var is3DMode: Bool
	@Binding var region: MKCoordinateRegion
	@ObservedObject var locationManager: LocationManager
	
	@State private var toggle3DPressed = false
	@State private var toggle3DScale: CGFloat = 1.0
	@State private var locationPressed = false
	@State private var locationScale: CGFloat = 1.0
	
	var body: some View {
		VStack {
			HStack {
				Spacer()
				VStack(spacing: 8) {
					// 3D mode toggle button
					Button(action: {
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()
						
						withAnimation(.easeInOut(duration: 0.3)) {
							is3DMode.toggle()
						}
					}) {
						Image(systemName: is3DMode ? "view.3d" : "view.2d")
							.font(.system(size: 18))
							.foregroundColor(universalAccentColor)
							.padding(12)
							.background(universalBackgroundColor)
							.clipShape(Circle())
							.shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
							.scaleEffect(toggle3DScale)
					}
					.buttonStyle(PlainButtonStyle())
					.animation(.easeInOut(duration: 0.15), value: toggle3DScale)
					.onLongPressGesture(
						minimumDuration: 0,
						maximumDistance: .infinity,
						pressing: { pressing in
							toggle3DPressed = pressing
							toggle3DScale = pressing ? 0.95 : 1.0
							if pressing {
								let selectionGenerator = UISelectionFeedbackGenerator()
								selectionGenerator.selectionChanged()
							}
						},
						perform: {}
					)
					
					// Location button
					Button(action: {
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()
						
						if let userLocation = locationManager.userLocation {
							withAnimation(.easeInOut(duration: 0.75)) {
								region = MKCoordinateRegion(
									center: userLocation,
									span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
								)
							}
						}
					}) {
						Image(systemName: "location.fill")
							.font(.system(size: 18))
							.foregroundColor(universalAccentColor)
							.padding(12)
							.background(universalBackgroundColor)
							.clipShape(Circle())
							.shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
							.scaleEffect(locationScale)
					}
					.buttonStyle(PlainButtonStyle())
					.animation(.easeInOut(duration: 0.15), value: locationScale)
					.onLongPressGesture(
						minimumDuration: 0,
						maximumDistance: .infinity,
						pressing: { pressing in
							locationPressed = pressing
							locationScale = pressing ? 0.95 : 1.0
							if pressing {
								let selectionGenerator = UISelectionFeedbackGenerator()
								selectionGenerator.selectionChanged()
							}
						},
						perform: {}
					)
				}
				.padding(.trailing, 16)
			}
			.padding(.top, 16)
			
			Spacer()
		}
	}
}


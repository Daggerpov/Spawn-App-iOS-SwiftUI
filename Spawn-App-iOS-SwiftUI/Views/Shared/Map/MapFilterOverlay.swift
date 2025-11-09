//
//  MapFilterOverlay.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/8/25.
//

import SwiftUI

struct MapFilterOverlay: View {
	@Binding var showFilterOverlay: Bool
	@Binding var selectedTimeFilter: TimeFilter

	enum TimeFilter: String, CaseIterable {
		case lateNight = "Late Night"
		case evening = "Evening"
		case afternoon = "Afternoon"
		case inTheNextHour = "In the next hour"
		case happeningNow = "Happening Now"
		case allActivities = "All Activities"
	}

	var body: some View {
		ZStack {
			// Dimming overlay
			if showFilterOverlay {
				Color.black.opacity(0.3)
					.ignoresSafeArea()
					.transition(.opacity)
					.contentShape(Rectangle())
					.onTapGesture {
						withAnimation(.spring()) {
							showFilterOverlay = false
						}
					}
			}

			// Filter buttons
			VStack {
				Spacer()
				HStack {
					Spacer()
					VStack(spacing: 8) {
						if showFilterOverlay {
							// Show "All Activities" at the top if not selected
							if selectedTimeFilter != .allActivities {
								filterButton(for: .allActivities)
							}

							// Show all other filters except currently selected and "All Activities"
							ForEach(
								Array(TimeFilter.allCases.dropLast().filter { $0 != selectedTimeFilter }).reversed(),
								id: \.self
							) { filter in
								filterButton(for: filter)
									.transition(.move(edge: .top).combined(with: .opacity))
							}
						}

						// Main filter button (always visible)
						Button(action: {
							withAnimation(.spring()) {
								showFilterOverlay.toggle()
							}
						}) {
							HStack {
								Circle()
									.fill(figmaGreen)
									.frame(width: 10, height: 10)
								Text(selectedTimeFilter.rawValue)
									.font(.onestMedium(size: 16))
									.foregroundColor(universalAccentColor)
							}
							.frame(maxWidth: .infinity, alignment: .center)
							.padding(.vertical, 12)
							.padding(.horizontal, 16)
							.background(universalBackgroundColor)
							.cornerRadius(20)
							.shadow(radius: 2)
						}
					}
					.frame(maxWidth: 155)
					.padding(.trailing, 20)
				}
				.padding(.bottom, 80)
			}
		}
	}

	private func filterButton(for filter: TimeFilter) -> some View {
		Button(action: {
			withAnimation(.spring()) {
				selectedTimeFilter = filter
				showFilterOverlay = false
			}
		}) {
			HStack {
				Text(filter.rawValue)
					.font(.onestMedium(size: 16))
					.foregroundColor(universalAccentColor)
			}
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.vertical, 12)
			.padding(.horizontal, 16)
			.background(universalBackgroundColor)
			.cornerRadius(20)
		}
	}
}

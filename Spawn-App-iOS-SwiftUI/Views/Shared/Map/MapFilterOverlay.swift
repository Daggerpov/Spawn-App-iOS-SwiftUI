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
			// Figma "Open Filters" (node 442:5504) blurs the map behind the menu rather than dimming it
			if showFilterOverlay {
				Rectangle()
					.fill(.ultraThinMaterial)
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
							// Figma order, top to bottom: Late Night, Evening, Afternoon, In the next hour,
							// Happening Now, then All Activities right above the selected filter
							ForEach(
								TimeFilter.allCases.filter { $0 != selectedTimeFilter },
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
							filterLabel(for: selectedTimeFilter, isSelected: true)
						}
					}
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
			filterLabel(for: filter, isSelected: false)
		}
	}

	/// Shared pill so every option lines up: same width, same dot column, text leading aligned
	private func filterLabel(for filter: TimeFilter, isSelected: Bool) -> some View {
		HStack(spacing: 8) {
			Circle()
				.fill(isSelected ? figmaGreen : Color.clear)
				.frame(width: 10, height: 10)
			// Sized for the longest option so the pills keep one width
			ZStack(alignment: .leading) {
				ForEach(TimeFilter.allCases, id: \.self) { option in
					Text(option.rawValue).hidden()
				}
				Text(filter.rawValue)
			}
			.font(.onestMedium(size: 16))
			.foregroundColor(universalAccentColor)
			.lineLimit(1)
		}
		.padding(.vertical, 12)
		.padding(.horizontal, 16)
		.background(universalBackgroundColor)
		.cornerRadius(20)
		.shadow(radius: 2)
	}
}

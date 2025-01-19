//
//  EventCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct EventCreationView: View {
	@ObservedObject var viewModel: EventCreationViewModel

	@State private var selectedDate: Date = Date()  // New local state for the selected date

	init(creatingUser: User) {
		self.viewModel = EventCreationViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService(),
			creatingUser: creatingUser
		)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			Spacer()
			EventInputFieldLabel(text: "event name")
			EventInputField(value: $viewModel.event.title)

			EventInputFieldLabel(text: "date")
			DatePicker(
				"Select Date",
				selection: $selectedDate,
				displayedComponents: .date
			)
			.datePickerStyle(GraphicalDatePickerStyle())
			.labelsHidden()

			HStack(spacing: 16) {
				VStack {
					EventInputFieldLabel(text: "start time")
					TimePicker(
						iconName: "clock",
						date: Binding(
							get: {
								viewModel.event.startTime
									?? combineDateAndTime(
										selectedDate, time: Date())
							},
							set: { time in
								viewModel.event.startTime = combineDateAndTime(
									selectedDate, time: time)
							}
						)
					)
				}
				VStack {
					EventInputFieldLabel(text: "end time")
					TimePicker(
						iconName: "clock.arrow.circlepath",
						date: Binding(
							get: {
								viewModel.event.endTime
									?? combineDateAndTime(
										selectedDate, time: Date())
							},
							set: { time in
								viewModel.event.endTime = combineDateAndTime(
									selectedDate, time: time)
							}
						)
					)
				}
			}

			EventInputFieldLabel(text: "location")
			EventInputField(
				iconName: "mappin.and.ellipse",
				value: Binding(
					get: {
						viewModel.event.location?.name ?? ""
					},
					set: {
						viewModel.event.location?.name =
							((($0?.isEmpty) != nil) ? nil : $0) ?? ""
					}
				)
			)

			EventInputFieldLabel(text: "description")
			EventInputField(
				value: Binding(
					get: {
						viewModel.event.note ?? ""
					},
					set: {
						viewModel.event.note = (($0?.isEmpty) != nil) ? nil : $0
					}
				)
			)

			Button(action: {
				Task {
					await viewModel.createEvent()
				}
			}) {
				Text("spawn")
					.font(Font.custom("Poppins", size: 20).weight(.medium))
					.frame(maxWidth: .infinity)
					.kerning(1)
					.multilineTextAlignment(.center)
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 15).fill(
							universalAccentColor)
					)
					.foregroundColor(.white)
			}
			.padding(.top, 20)
		}
		.padding()
		.background(universalBackgroundColor)
		.cornerRadius(15)
		.shadow(radius: 10)
		.padding(.horizontal, 20)
		.padding(.bottom, 200)
	}

	// Helper function to combine a date and a time into a single Date
	private func combineDateAndTime(_ date: Date, time: Date) -> Date {
		let calendar = Calendar.current
		let dateComponents = calendar.dateComponents(
			[.year, .month, .day], from: date)
		let timeComponents = calendar.dateComponents(
			[.hour, .minute], from: time)
		var combinedComponents = DateComponents()
		combinedComponents.year = dateComponents.year
		combinedComponents.month = dateComponents.month
		combinedComponents.day = dateComponents.day
		combinedComponents.hour = timeComponents.hour
		combinedComponents.minute = timeComponents.minute
		return calendar.date(from: combinedComponents) ?? date
	}
}

struct EventInputFieldLabel: View {
	var text: String

	var body: some View {
		VStack {
			Text(text)
				.font(Font.custom("Poppins", size: 16))
				.kerning(0.8)
				.foregroundColor(Color(red: 0.11, green: 0.24, blue: 0.24))
				.frame(
					maxWidth: .infinity, minHeight: 16, maxHeight: 16,
					alignment: .topLeading)
		}
	}
}

struct EventInputField: View {
	var iconName: String?
	@Binding var value: String?

	var body: some View {
		HStack {
			if let icon = iconName {
				Image(systemName: icon)
					.foregroundColor(.secondary)
			}
			TextField(
				"",
				text: Binding(
					get: { value ?? "" },
					set: { value = $0.isEmpty ? nil : $0 }
				)
			)
			.foregroundColor(.primary)
		}
		.padding()
		.background(
			Rectangle()
				.foregroundColor(.clear)
				.frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
				.cornerRadius(15)
				.overlay(
					RoundedRectangle(cornerRadius: 15)
						.inset(by: 0.75)
						.stroke(.black, lineWidth: 1.5)
				)
		)
	}
}

struct TimePicker: View {
	var iconName: String
	@Binding var date: Date

	var body: some View {
		HStack {
			Image(systemName: iconName)
				.foregroundColor(.secondary)
			DatePicker(
				"",
				selection: $date,
				displayedComponents: .hourAndMinute
			)
			.labelsHidden()
		}
		.padding()
		.background(
			Rectangle()
				.foregroundColor(.clear)
				.frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
				.cornerRadius(15)
				.overlay(
					RoundedRectangle(cornerRadius: 15)
						.inset(by: 0.75)
						.stroke(.black, lineWidth: 1.5)
				)
		)
	}
}

#Preview {
	EventCreationView(creatingUser: User.danielAgapov)
}

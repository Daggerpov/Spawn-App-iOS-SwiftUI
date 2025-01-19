//
//  EventCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct EventCreationView: View {
	@ObservedObject var viewModel: EventCreationViewModel

	@State private var selectedDate: Date = Date()  // Local state for the selected date
	@State private var showFullDatePicker: Bool = false  // Toggles the pop-out calendar

	init(creatingUser: User) {
		self.viewModel = EventCreationViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService(),
			creatingUser: creatingUser
		)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			EventInputFieldLabel(text: "event name")
			EventInputField(value: $viewModel.event.title)

			EventInputFieldLabel(text: "date")
			Button(action: { showFullDatePicker = true }) {
				HStack {
					Image(systemName: "calendar")
						.foregroundColor(.secondary)
					Text(viewModel.formatDate(selectedDate))
						.padding()
						.foregroundColor(.primary)
						.background(
						Rectangle()
							.foregroundColor(Color("#D9D9D2"))
							.background(Color(.init(gray: 0, alpha: 0.055)))
							.frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
							.cornerRadius(15)
					)
				}
				.padding()

			}
			.sheet(isPresented: $showFullDatePicker) {
				VStack {
					Text("Select a Date")
						.font(.headline)
						.padding()
					DatePicker(
						"Select Date",
						selection: $selectedDate,
						displayedComponents: .date
					)
					.datePickerStyle(GraphicalDatePickerStyle())
					.labelsHidden()
					.padding()

					Button("Done") {
						showFullDatePicker = false
					}
					.padding()
					.frame(maxWidth: .infinity)
					.foregroundColor(Color(.systemGray6))
					.cornerRadius(10)
					.padding()
				}
				.presentationDetents([.medium])
			}

			HStack(spacing: 16) {
				VStack {
					EventInputFieldLabel(text: "start time")
						.padding(.leading, 8)
					TimePicker(
						iconName: "clock",
						date: Binding(
							get: {
								viewModel.event.startTime
								?? viewModel.combineDateAndTime(
										selectedDate, time: Date())
							},
							set: { time in
								viewModel.event.startTime = viewModel.combineDateAndTime(
									selectedDate, time: time)
							}
						)
					)
				}

				VStack {
					EventInputFieldLabel(text: "end time")
						.padding(.leading, 8)
					TimePicker(
						iconName: "clock.arrow.circlepath",
						date: Binding(
							get: {
								viewModel.event.endTime
								?? viewModel.combineDateAndTime(
										selectedDate, time: Date()
											.addingTimeInterval(2 * 60 * 60) // adds 2 hours
									)
							},
							set: { time in
								viewModel.event.endTime = viewModel.combineDateAndTime(
									selectedDate, time: time)
							}
						)
					)
				}
				Spacer()
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
		.padding(32)
		.background(universalBackgroundColor)
		.cornerRadius(15)
		.shadow(radius: 10)
		.padding(.horizontal, 20)
		.padding(.vertical , 100)
	}
}

struct EventInputFieldLabel: View {
	var text: String

	var body: some View {
		VStack {
			Text(text)
				.font(Font.custom("Poppins", size: 20))
				.kerning(1)
				.foregroundColor(universalAccentColor)
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
		)
	}
}

#Preview {
	EventCreationView(creatingUser: User.danielAgapov)
}

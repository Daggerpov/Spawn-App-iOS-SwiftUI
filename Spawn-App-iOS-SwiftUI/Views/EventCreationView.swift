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

	private var creatingUser: User

	init(creatingUser: User) {
		self.creatingUser = creatingUser
		self.viewModel = EventCreationViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: creatingUser.id) : APIService(),
			creatingUser: creatingUser)
	}

	var body: some View {
		NavigationStack{
			VStack(alignment: .leading, spacing: 20) {
				EventInputFieldLabel(text: "event name")
				EventInputField(value: $viewModel.event.title)

				HStack {
					VStack(alignment: .leading) {
						EventInputFieldLabel(text: "date")
						HStack {
							Image(systemName: "calendar")
								.resizable()
								.frame(width: 24, height: 24)
								.foregroundColor(.secondary)
								.padding(.leading)
							Button(action: { showFullDatePicker = true }) {
								Text(viewModel.formatDate(selectedDate))
									.padding()
									.foregroundColor(.primary)
									.background(
										Rectangle()
											.foregroundColor(Color("#D9D9D2"))
											.background(
												Color(.init(gray: 0, alpha: 0.055))
											)
											.frame(
												maxWidth: .infinity, minHeight: 46,
												maxHeight: 46
											)
											.cornerRadius(15)
									)
							}
						}
						.sheet(isPresented: $showFullDatePicker) {
							fullDatePickerView
						}
					}

					Spacer()

					VStack(alignment: .leading) {
						EventInputFieldLabel(text: "invite friends")
						Spacer()
						NavigationLink(destination: {
							InviteView(user: creatingUser)
						}) {
							HStack {
								Spacer()
								Circle()
									.fill(Color.gray.opacity(0.2))
									.frame(width: 30, height: 30)
									.overlay(
										Circle()
											.stroke(
												.secondary,
												style: StrokeStyle(
													lineWidth: 2,
													dash: [5, 3]  // Length of dash and gap
												)
											)
									)
									.overlay(
										Image(systemName: "plus")
											.foregroundColor(.secondary)
									)
							}
						}
					}
				}

				HStack {
					VStack(alignment: .leading) {
						EventInputFieldLabel(text: "start time")
						startTimeView
					}
					Spacer()
					VStack(alignment: .leading) {
						EventInputFieldLabel(text: "end time")
						endTimeView
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
						.font(Font.custom("Poppins", size: 16).weight(.medium))
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
			.padding(.vertical, 100)
		}
	}
}

struct EventInputFieldLabel: View {
	var text: String

	var body: some View {
		Text(text)
			.font(Font.custom("Poppins", size: 16))
			.kerning(1)
			.foregroundColor(universalAccentColor)
			.bold()
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
	var wideImage: Bool?
	@Binding var date: Date

	var body: some View {
		HStack {
			if let wide = wideImage {
				Image(systemName: iconName)
					.resizable()
					.frame(width: 32, height: 26)
					.foregroundColor(.secondary)
			} else {
				Image(systemName: iconName)
					.resizable()
					.frame(width: 24, height: 24)
					.foregroundColor(.secondary)
			}

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
				.frame(maxWidth: .infinity)
				.cornerRadius(15)
		)
	}

	// Helper function to check if the date is the current time
	private func isNow(_ date: Date) -> Bool {
		let calendar = Calendar.current
		let now = Date()
		return calendar.isDate(date, inSameDayAs: now)
			&& calendar.component(.hour, from: date)
				== calendar.component(.hour, from: now)
			&& calendar.component(.minute, from: date)
				== calendar.component(.minute, from: now)
	}

	// Helper function to format the time
	private func formattedTime(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "h:mm a"  // Customize the format as needed
		return formatter.string(from: date)
	}
}

extension EventCreationView {
	var startTimeView: some View {
		TimePicker(
			iconName: "clock.fill",
			date: Binding(
				get: {
					viewModel.event.startTime
						?? viewModel.combineDateAndTime(
							selectedDate, time: Date())
				},
				set: { time in
					viewModel.event.startTime =
						viewModel.combineDateAndTime(
							selectedDate, time: time)
				}
			)
		)
	}

	var endTimeView: some View {
		TimePicker(
			iconName: "clock.badge.checkmark.fill",
			wideImage: true,
			date: Binding(
				get: {
					viewModel.event.endTime
						?? viewModel.combineDateAndTime(
							selectedDate,
							time: Date()
								.addingTimeInterval(2 * 60 * 60)  // adds 2 hours
						)
				},
				set: { time in
					viewModel.event.endTime = viewModel.combineDateAndTime(
						selectedDate, time: time)
				}
			)
		)
	}

	var fullDatePickerView: some View {
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
}

#Preview {
	EventCreationView(creatingUser: User.danielAgapov)
}

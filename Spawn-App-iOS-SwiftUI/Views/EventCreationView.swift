//
//  EventCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct EventCreationView: View {
	@ObservedObject var viewModel: EventCreationViewModel =
		EventCreationViewModel.shared

	@State private var showFullDatePicker: Bool = false  // Toggles the pop-out calendar

	var creatingUser: User
	var closeCallback: () -> Void

	init(creatingUser: User, closeCallback: @escaping () -> Void) {
		self.creatingUser = creatingUser
		self.closeCallback = closeCallback
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 12) {
					EventInputFieldLabel(text: "Event Name")
					EventInputField(value: $viewModel.event.title)

					VStack(alignment: .leading) {
						EventInputFieldLabel(text: "Invite Friends")
						Spacer()

						invitationsRowView
					}

					HStack {
						VStack(alignment: .leading) {
							EventInputFieldLabel(text: "Start Time")
							startTimeView
						}
						Spacer()
						VStack(alignment: .leading) {
							EventInputFieldLabel(text: "End Time")
							endTimeView
						}
					}

					HStack {
						Spacer()
						VStack(alignment: .leading) {
							EventInputFieldLabel(text: "Date")
							datePickerView
						}

						Spacer()
					}

					EventInputFieldLabel(text: "Location")
					EventInputField(
						iconName: "mappin.and.ellipse",
						// TODO DANIEL: change to also include input for lat & long by some map API selection
						value: Binding(
							get: { viewModel.event.location?.name ?? "" },
							set: { newValue in
								if let unwrappedNewValue = newValue {
									if viewModel.event.location == nil {
										viewModel.event.location = Location(
											id: UUID(), name: unwrappedNewValue,
											latitude: 0, longitude: 0)
									} else {
										viewModel.event.location?.name =
											unwrappedNewValue
									}
								}
							}
						)
					)

					EventInputFieldLabel(text: "Description")
					EventInputField(
						value: $viewModel.event.note
					)

					Button(action: {
						Task {
							await viewModel.createEvent()
						}
						closeCallback()
					}) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.white)
                            Text("Spawn")
                                .font(
                                    Font.custom("Poppins", size: 16).weight(.bold)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .kerning(1)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15).fill(
                                universalSecondaryColor)
                        )
                        .foregroundColor(.white)
					}
					.padding(.top, 20)

				}
				.padding(32)
				.background(universalBackgroundColor)
				.cornerRadius(universalRectangleCornerRadius)
				.shadow(radius: 10)
				.padding(.horizontal, 20)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			.scrollDisabled(true)
			.background(universalBackgroundColor)  // Set background color for the ScrollView
		}
		.background(universalBackgroundColor)  // Set background color for the NavigationStack
		.cornerRadius(universalRectangleCornerRadius)  // Apply corner radius to the NavigationStack
		.environmentObject(viewModel)
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
					set: { newValue in
						// Safely update the value outside of the view update
						DispatchQueue.main.async {
							value = newValue.isEmpty ? nil : newValue
						}
					}
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
			if wideImage != nil {
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
	var invitationsRowView: some View {
		HStack {
			selectedFriendsView
			Spacer()
			selectedTagsView
		}
	}

	var selectedFriendsView: some View {
		HStack {
			ForEach(viewModel.selectedFriends) { friend in
				if let pfpUrl = friend.profilePicture {
					AsyncImage(url: URL(string: pfpUrl)) {
						image in
						image
							.ProfileImageModifier(imageType: .eventParticipants)
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 25, height: 25)
					}
				} else {
					Circle()
						.fill(Color.gray)
						.frame(width: 25, height: 25)
				}
			}
			NavigationLink(destination: {
				InviteView(user: creatingUser)
					.environmentObject(viewModel)
			}) {
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
			.padding(.leading, 12)
		}
	}

	var selectedTagsView: some View {
		HStack {
			let displayedTags = viewModel.selectedTags
				.prefix(2)
			let remainingCount =
				viewModel.selectedTags.count
				- displayedTags.count

			ForEach(displayedTags) { tag in
				Text(tag.displayName)
					.font(
						.system(size: 14, weight: .medium)
					)
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.background(
						Color(hex: tag.colorHexCode)
					)
					.foregroundColor(.white)
					.clipShape(Capsule())
			}

			if remainingCount > 0 {
				Text("+\(remainingCount) more")
					.font(
						.system(size: 14, weight: .medium)
					)
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.background(universalAccentColor)
					.foregroundColor(.white)
					.clipShape(Capsule())
			}
		}
	}

	var startTimeView: some View {
		TimePicker(
			iconName: "clock.fill",
			date: Binding(
				get: {
					viewModel.event.startTime
						?? viewModel.combineDateAndTime(
							viewModel.selectedDate, time: Date())
				},
				set: { time in
					viewModel.event.startTime =
						viewModel.combineDateAndTime(
							viewModel.selectedDate, time: time)
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
							viewModel.selectedDate,
							time: Date()
								.addingTimeInterval(2 * 60 * 60)  // adds 2 hours
						)
				},
				set: { time in
					viewModel.event.endTime = viewModel.combineDateAndTime(
						viewModel.selectedDate, time: time)
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
				selection: $viewModel.selectedDate,
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

	var datePickerView: some View {
		HStack {
			Image(systemName: "calendar")
				.resizable()
				.frame(width: 24, height: 24)
				.foregroundColor(.secondary)
				.padding(.leading)
			Button(action: { showFullDatePicker = true }) {
				Text(viewModel.formatDate(viewModel.selectedDate))
					.padding()
					.foregroundColor(.primary)
					.background(
						Rectangle()
							.foregroundColor(
								Color(hex: "#D9D9D2")
							)
							.background(
								Color(
									.init(
										gray: 0,
										alpha: 0.055)
								)
							)
							.frame(
								maxWidth: .infinity,
								minHeight: 46,
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
}

#Preview {
	EventCreationView(creatingUser: User.danielAgapov, closeCallback: {})
}

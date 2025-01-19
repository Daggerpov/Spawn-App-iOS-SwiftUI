//
//  EventCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct EventCreationView: View {
	@ObservedObject var viewModel: EventCreationViewModel

	init(creatingUser: User) {
		self.viewModel = EventCreationViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService(), creatingUser: creatingUser)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			EventInputFieldLabel(text: "title")
			EventInputField(value: $viewModel.event.title)

			HStack(spacing: 16) {
				VStack {
					EventInputFieldLabel(text: "start time")
					TimePicker(
						iconName: "clock",
						date: Binding(
							get: { viewModel.event.startTime ?? Date() },
							set: { viewModel.event.startTime = $0 }
						))
				}
				VStack {
					EventInputFieldLabel(text: "end time")
					TimePicker(
						iconName: "clock.arrow.circlepath",
						date: Binding(
							get: { viewModel.event.endTime ?? Date() },
							set: { viewModel.event.endTime = $0 }
						))
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
					.font(
						Font.custom("Poppins", size: 20)
							.weight(.medium)
					)
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

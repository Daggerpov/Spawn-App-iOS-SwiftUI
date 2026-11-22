import SwiftUI

/// Hours (0–23) and minutes (quarter hours) for an activity length other than the presets.
struct CustomDurationPickerView: View {
	let onCancel: () -> Void
	let onSet: (Int) -> Void

	@State private var hours: Int
	@State private var minutes: Int

	private let hourOptions = Array(0...23)
	private let minuteOptions = [0, 15, 30, 45]

	init(initialMinutes: Int, onCancel: @escaping () -> Void, onSet: @escaping (Int) -> Void) {
		self.onCancel = onCancel
		self.onSet = onSet
		let clamped = max(0, initialMinutes)
		_hours = State(initialValue: min(clamped / 60, 23))
		_minutes = State(initialValue: ((clamped % 60) / 15) * 15)
	}

	private var totalMinutes: Int { hours * 60 + minutes }

	var body: some View {
		VStack(spacing: 8) {
			HStack {
				Button("Cancel", action: onCancel)
					.font(.onestMedium(size: 16))
					.foregroundColor(figmaBlack300)

				Spacer()

				Text("How long?")
					.font(.onestSemiBold(size: 20))
					.foregroundColor(universalAccentColor)

				Spacer()

				Button("Set") { onSet(totalMinutes) }
					.font(.onestSemiBold(size: 16))
					.foregroundColor(totalMinutes > 0 ? Color(hex: colorsIndigo500) : figmaBlack300)
					.disabled(totalMinutes == 0)
			}
			.padding(.horizontal, 20)
			.padding(.top, 20)

			HStack(spacing: 4) {
				Picker("Hours", selection: $hours) {
					ForEach(hourOptions, id: \.self) { hour in
						Text("\(hour)")
							.font(.onestMedium(size: 22))
							.tag(hour)
					}
				}
				.pickerStyle(.wheel)
				.frame(width: 70)
				.clipped()

				Text("hr")
					.font(.onestMedium(size: 16))
					.foregroundColor(figmaBlack300)

				Picker("Minutes", selection: $minutes) {
					ForEach(minuteOptions, id: \.self) { minute in
						Text(String(format: "%02d", minute))
							.font(.onestMedium(size: 22))
							.tag(minute)
					}
				}
				.pickerStyle(.wheel)
				.frame(width: 70)
				.clipped()
				.padding(.leading, 16)

				Text("min")
					.font(.onestMedium(size: 16))
					.foregroundColor(figmaBlack300)
			}
			.frame(maxWidth: .infinity)
		}
		.padding(.bottom, 12)
		.frame(maxHeight: .infinity, alignment: .top)
		.presentationBackground(universalBackgroundColor)
	}
}

@available(iOS 17, *)
#Preview {
	CustomDurationPickerView(initialMinutes: 180, onCancel: {}, onSet: { _ in })
}

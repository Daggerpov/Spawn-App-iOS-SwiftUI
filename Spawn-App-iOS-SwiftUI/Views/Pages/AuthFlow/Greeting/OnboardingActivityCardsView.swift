import SwiftUI

/// Decorative examples only: no account data, profile photos, or network requests.
struct OnboardingActivityCardsView: View {
	var body: some View {
		GeometryReader { geometry in
			ZStack(alignment: .topLeading) {
				card("Morning Jog", host: "Jamie Park", time: "7–8:30 AM",
					location: "Main Mall · 100m away", symbol: "figure.run",
					color: colorsRed600, happeningNow: true)
					.rotationEffect(.degrees(-5))
					.offset(x: 5, y: 25)

				card("Lunch Break", host: "Casey Rivera", time: "12–1 PM",
					location: "Campus Café · 450m away", symbol: "fork.knife",
					color: colorsTeal600)
					.scaleEffect(0.75, anchor: .topLeading)
					.rotationEffect(.degrees(-10), anchor: .topLeading)
					.offset(x: 305, y: 75)

				card("Hoop Run", host: "Morgan Lee", time: "1–2:30 PM",
					location: "Rec Centre · 500m away", symbol: "basketball",
					color: colorsPurple600, width: 240)
					.scaleEffect(0.8, anchor: .topLeading)
					.rotationEffect(.degrees(-10), anchor: .topLeading)
					.offset(x: 0, y: 195)

				card("Climb Sesh", host: "Taylor Reed", time: "7–8:30 AM",
					location: "Climbing Gym · 800m away", symbol: "figure.climbing",
					color: colorsBlue600, width: 244)
					.rotationEffect(.degrees(5), anchor: .topLeading)
					.offset(x: 218, y: 155)
			}
			.frame(width: 462, height: 266, alignment: .topLeading)
			.scaleEffect(geometry.size.width / 462, anchor: .topLeading)
		}
		.aspectRatio(462.0 / 266, contentMode: .fit)
		.clipped()
		.accessibilityElement(children: .ignore)
		.accessibilityLabel("Example activities with fictional hosts and placeholder avatars")
	}

	private func card(
		_ title: String, host: String, time: String, location: String,
		symbol: String, color: String, happeningNow: Bool = false, width: CGFloat = 270
	) -> some View {
		VStack(alignment: .leading, spacing: 9) {
			HStack(alignment: .top, spacing: 8) {
				VStack(alignment: .leading, spacing: 4) {
					Text(title)
						.font(.onestSemiBold(size: 14))
					Text("By \(host) · \(time)")
						.font(.onestRegular(size: 9))
				}
				Spacer(minLength: 0)
				HStack(spacing: -5) {
					ForEach(0..<2) { _ in
						Image(systemName: "person.fill")
							.font(.system(size: 10))
							.frame(width: 21, height: 21)
							.background(.white.opacity(0.25), in: Circle())
							.overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1))
					}
					Text("+12")
						.font(.onestMedium(size: 8))
						.foregroundStyle(Color(hex: color))
						.frame(width: 22, height: 22)
						.background(.white, in: Circle())
				}
			}

			HStack(spacing: 6) {
				Label(location, systemImage: symbol)
					.font(.onestMedium(size: 9))
					.padding(.horizontal, 7)
					.padding(.vertical, 4)
					.background(.black.opacity(0.13), in: Capsule())
				Spacer(minLength: 0)
				Text(happeningNow ? "Happening Now" : "Later Today")
					.font(.onestMedium(size: 8))
					.foregroundStyle(happeningNow ? Color.black : Color(.label))
					.padding(.horizontal, 6)
					.padding(.vertical, 4)
					.background(happeningNow ? figmaGreen : Color(.systemGray5), in: Capsule())
			}
		}
		.foregroundStyle(.white)
		.padding(11)
		.frame(width: width, height: 94)
		.background(ActivityCardGradientBackground(color: Color(hex: color), cornerRadius: 10))
		.shadow(color: .black.opacity(0.12), radius: 3, y: 3)
	}
}

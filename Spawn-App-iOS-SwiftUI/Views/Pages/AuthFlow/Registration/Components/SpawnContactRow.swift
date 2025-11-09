import SwiftUI

struct SpawnContactRow: View {
	let contactOnSpawn: ContactsOnSpawn
	let isAdded: Bool
	let onAdd: () -> Void
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme
	@State private var isAnimatingAdd: Bool = false

	var body: some View {
		HStack(spacing: 12) {
			// Profile Picture
			AsyncImage(url: contactOnSpawn.spawnUser.profilePicture.flatMap { URL(string: $0) }) { image in
				image
					.resizable()
					.scaledToFill()
			} placeholder: {
				Circle()
					.fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
					.overlay(
						Text(String(contactOnSpawn.contact.name.prefix(1)))
							.font(.system(size: 16, weight: .semibold))
							.foregroundColor(.white)
					)
			}
			.frame(width: 36, height: 36)
			.clipShape(Circle())
			.shadow(color: Color.black.opacity(0.25), radius: 4.06, y: 1.62)

			VStack(alignment: .leading, spacing: 2) {
				Text(contactOnSpawn.contact.name)
					.font(Font.custom("Onest", size: 14).weight(.semibold))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))

				Text("@\(contactOnSpawn.spawnUser.username ?? "username")")
					.font(Font.custom("Onest", size: 12))
					.foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
			}

			Spacer()

			// Add button with friends tab styling
			Button(action: {
				withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
					isAnimatingAdd = true
				}
				onAdd()
			}) {
				HStack(spacing: 6) {
					if isAdded {
						Image(systemName: "checkmark")
							.font(.system(size: 14, weight: .bold))
							.foregroundColor(.white)
							.transition(.scale.combined(with: .opacity))
					} else {
						Text("Add +")
							.font(Font.custom("Onest", size: 14).weight(.medium))
							.transition(.scale.combined(with: .opacity))
					}
				}
				.foregroundColor(isAdded ? .white : .gray)
				.padding(12)
				.background(
					RoundedRectangle(cornerRadius: 8)
						.fill(
							isAdded ? universalAccentColor(from: themeService, environment: colorScheme) : Color.clear
						)
						.animation(.easeInOut(duration: 0.3), value: isAdded)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 8)
						.stroke(
							isAdded ? universalAccentColor(from: themeService, environment: colorScheme) : .gray,
							lineWidth: 1
						)
						.animation(.easeInOut(duration: 0.3), value: isAdded)
				)
				.frame(minHeight: 46, maxHeight: 46)
			}
			.buttonStyle(PlainButtonStyle())
			.disabled(isAdded)
		}
		.padding(.vertical, 8)
	}
}

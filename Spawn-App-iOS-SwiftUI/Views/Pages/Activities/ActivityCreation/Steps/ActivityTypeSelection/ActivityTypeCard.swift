import SwiftUI

struct ActivityTypeCard: View {
	let activityTypeDTO: ActivityTypeDTO
	@Binding var selectedActivityType: ActivityTypeDTO?
	let onPin: () -> Void
	let onDelete: () -> Void
	let onManage: () -> Void

	// Add state to track button interaction
	@State private var isPressed = false

	@Environment(\.colorScheme) private var colorScheme

	private var isSelected: Bool {
		selectedActivityType?.id == activityTypeDTO.id
	}

	// Adaptive background color for card
	private var adaptiveBackgroundColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.24, green: 0.23, blue: 0.23)
		case .light:
			return Color(red: 0.95, green: 0.93, blue: 0.93)
		@unknown default:
			return Color(red: 0.95, green: 0.93, blue: 0.93)
		}
	}

	// Adaptive text colors
	private var adaptiveTitleColor: Color {
		switch colorScheme {
		case .dark:
			return .white
		case .light:
			return Color(red: 0.11, green: 0.11, blue: 0.11)
		@unknown default:
			return Color(red: 0.11, green: 0.11, blue: 0.11)
		}
	}

	private var adaptiveSecondaryTextColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.82, green: 0.80, blue: 0.80)
		case .light:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		@unknown default:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		}
	}

	// Computed properties for dynamic styling
	private var backgroundFillColor: Color {
		if isSelected {
			return Color.blue.opacity(0.1)
		} else {
			return adaptiveBackgroundColor
		}
	}

	private var borderColor: Color {
		if isSelected {
			return Color.clear
		} else {
			return Color.clear
		}
	}

	private var borderWidth: CGFloat {
		if isSelected {
			return 2
		} else {
			return 0
		}
	}

	private var shadowColor: Color {
		if isSelected {
			return Color.blue.opacity(0.3)
		} else {
			return Color.black.opacity(0.1)
		}
	}

	private var shadowRadius: CGFloat {
		if isSelected {
			return 4
		} else {
			return 2
		}
	}

	private var shadowOffset: CGFloat {
		if isSelected {
			return 2
		} else {
			return 1
		}
	}

	var body: some View {
		Button(action: {
			// Haptic feedback
			let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
			impactGenerator.impactOccurred()

			// Execute action with slight delay for animation
			Task { @MainActor in
				try? await Task.sleep(for: .seconds(0.1))
				selectedActivityType = activityTypeDTO
			}
		}) {
			ZStack {
				VStack(spacing: 10) {
					// Icon
					ZStack {
						Text(activityTypeDTO.icon)
							.font(.system(size: 24))
					}
					.frame(width: 32, height: 32)

					// Title and people count
					VStack {
						Text(activityTypeDTO.title)
							.font(Font.custom("Onest", size: 14).weight(.medium))
							.foregroundColor(adaptiveTitleColor)
							.lineLimit(2)
							.truncationMode(.tail)
							.multilineTextAlignment(.center)

						Text("\(activityTypeDTO.associatedFriends.count) people")
							.font(Font.custom("Onest", size: 12))
							.foregroundColor(adaptiveSecondaryTextColor)
					}
				}
				.padding(16)
				.frame(width: 116, height: 116)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(backgroundFillColor)
						.overlay(
							RoundedRectangle(cornerRadius: 12)
								.stroke(borderColor, lineWidth: borderWidth)
						)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 12)
						.stroke(Color(red: 0.95, green: 0.93, blue: 0.93), lineWidth: 1)  // "border"
						.shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: -2)  // dark shadow top
						.clipShape(RoundedRectangle(cornerRadius: 12))
						.shadow(color: Color.white.opacity(0.7), radius: 4, x: 0, y: 4)  // light shadow bottom
						.clipShape(RoundedRectangle(cornerRadius: 12))
				)

				// Pin icon overlay
				if activityTypeDTO.isPinned {
					VStack {
						HStack {
							Image(systemName: "pin.fill")
								.foregroundColor(.white)
								.font(.system(size: 8))
								.padding(3)
								.rotationEffect(.degrees(45))
								.background(Color(hex: colorsRed600))
								.clipShape(Circle())
							Spacer()
						}

						Spacer()
					}
					.padding(8)
				}
			}
		}
		.buttonStyle(PlainButtonStyle())
		.contextMenu {
			Button(action: onPin) {
				Label(
					activityTypeDTO.isPinned ? "Unpin" : "Pin",
					systemImage: activityTypeDTO.isPinned ? "pin.slash" : "pin"
				)
			}

			Button(action: onManage) {
				Label("Manage", systemImage: "gear")
			}

			Button(action: onDelete) {
				Label("Delete", systemImage: "trash")
			}
			.foregroundColor(.red)
		}
	}
}

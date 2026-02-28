import SwiftUI

struct ActivityTypeCard: View {
	let activityTypeDTO: ActivityTypeDTO
	let isSelected: Bool
	let onTap: () -> Void
	var onPin: (() -> Void)? = nil
	var onDelete: (() -> Void)? = nil
	var onManage: (() -> Void)? = nil

	@Environment(\.colorScheme) private var colorScheme

	private var hasContextMenu: Bool {
		onPin != nil && onDelete != nil && onManage != nil
	}

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

	var body: some View {
		let card = Button(action: {
			let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
			impactGenerator.impactOccurred()

			Task { @MainActor in
				try? await Task.sleep(for: .seconds(0.1))
				onTap()
			}
		}) {
			ZStack {
				VStack(spacing: 12) {
					Text(activityTypeDTO.icon)
						.font(.system(size: 24))
						.frame(width: 32, height: 32)

					VStack(spacing: 8) {
						Text(activityTypeDTO.title)
							.font(.onestMedium(size: 16))
							.foregroundColor(adaptiveTitleColor)
							.lineLimit(2)
							.truncationMode(.tail)
							.multilineTextAlignment(.center)

						Text("\(activityTypeDTO.associatedFriends.count) people")
							.font(.onestRegular(size: 12))
							.foregroundColor(adaptiveSecondaryTextColor)
					}
				}
				.padding(16)
				.frame(width: 116, height: 116)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(adaptiveBackgroundColor)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 12)
						.fill(
							LinearGradient(
								stops: [
									.init(color: Color.black.opacity(0.05), location: 0),
									.init(color: Color.clear, location: 0.3),
								],
								startPoint: .bottom,
								endPoint: .top
							)
						)
				)
				.overlay(
					RoundedRectangle(cornerRadius: 12)
						.stroke(
							isSelected ? Color(hex: colorsIndigo500) : Color.clear,
							lineWidth: isSelected ? 2.5 : 0
						)
				)
				.clipShape(RoundedRectangle(cornerRadius: 12))

				if activityTypeDTO.isPinned && hasContextMenu {
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

		if let onPin = onPin, let onDelete = onDelete, let onManage = onManage {
			card
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
		} else {
			card
		}
	}
}

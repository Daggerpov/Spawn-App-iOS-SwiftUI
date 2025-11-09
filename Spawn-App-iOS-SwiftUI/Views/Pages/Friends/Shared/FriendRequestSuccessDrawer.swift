import SwiftUI

struct FriendRequestSuccessDrawer: View {
	let friendUser: BaseUserDTO
	@Binding var isPresented: Bool
	let onAddToActivityType: () -> Void

	// Drag state tracking
	@State private var dragOffset: CGFloat = 0
	@State private var isDragging: Bool = false

	// Theme
	@ObservedObject private var themeService = ThemeService.shared
	@Environment(\.colorScheme) private var colorScheme

	// Adaptive Colors
	private var adaptiveOverlayColor: Color {
		switch colorScheme {
		case .dark: return Color.black.opacity(0.60)
		case .light: return Color.black.opacity(0.40)
		@unknown default: return Color.black.opacity(0.40)
		}
	}

	private var adaptiveDrawerBackground: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.12, green: 0.12, blue: 0.12)
		case .light: return Color(red: 0.95, green: 0.93, blue: 0.93)
		@unknown default: return Color(red: 0.95, green: 0.93, blue: 0.93)
		}
	}

	private var adaptiveTitleColor: Color {
		universalAccentColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveSecondaryTextColor: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.82, green: 0.80, blue: 0.80)
		case .light: return Color(red: 0.52, green: 0.49, blue: 0.49)
		@unknown default: return Color(red: 0.52, green: 0.49, blue: 0.49)
		}
	}

	private var adaptiveHandleColor: Color { Color(.systemGray4) }
	private var adaptiveBorderColor: Color { ThemeService.shared.borderColor(for: colorScheme) }

	var body: some View {
		ZStack {
			// Background overlay
			adaptiveOverlayColor
				.ignoresSafeArea()
				.onTapGesture {
					dismissDrawer()
				}

			// Drawer content
			VStack(spacing: 0) {
				Spacer()

				// Main drawer
				VStack(spacing: 16) {
					// Drag handle
					RoundedRectangle(cornerRadius: 100)
						.fill(adaptiveHandleColor)
						.frame(width: 50, height: 4)
						.padding(.top, 12)

					Spacer().frame(height: 24)

					// Success icon
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 64, weight: .bold))
						.foregroundColor(Color(hex: "#30D996"))

					// Success message
					Text("Success!")
						.font(.onestSemiBold(size: 24))
						.foregroundColor(adaptiveTitleColor)
						.padding(.top, 8)

					Text("You've added \(friendUser.name ?? friendUser.username ?? "Unknown") as a friend")
						.font(.onestMedium(size: 16))
						.foregroundColor(adaptiveSecondaryTextColor)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 32)
						.padding(.top, 8)

					// Add to Activity Type button
					Button(action: {
						dismissDrawer()
						onAddToActivityType()
					}) {
						HStack(spacing: 12) {
							Image(systemName: "person.badge.plus")
								.font(.system(size: 20, weight: .semibold))
								.foregroundColor(.white)

							Text("Add to Activity Type")
								.font(.onestSemiBold(size: 20))
								.foregroundColor(.white)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(figmaBlue)
						.cornerRadius(16)
					}
					.padding(.horizontal, 32)
					.padding(.top, 32)

					Spacer().frame(height: 32)
				}
				.frame(maxWidth: .infinity)
				.background(adaptiveDrawerBackground)
				.cornerRadius(20)
				.overlay(
					RoundedRectangle(cornerRadius: 20)
						.stroke(adaptiveBorderColor, lineWidth: 0.5)
				)
				.shadow(color: Color.black.opacity(0.1), radius: 32)
				.offset(y: dragOffset)
				.gesture(
					DragGesture()
						.onChanged { value in
							isDragging = true
							// Only allow dragging down
							if value.translation.height > 0 {
								dragOffset = value.translation.height
							}
						}
						.onEnded { value in
							isDragging = false

							// Dismiss threshold - if dragged down enough, dismiss
							let dismissThreshold: CGFloat = 100

							if value.translation.height > dismissThreshold {
								dismissDrawer()
							} else {
								// Snap back to position
								withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
									dragOffset = 0
								}
							}
						}
				)
			}
		}
		.animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
	}

	private func dismissDrawer() {
		withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
			isPresented = false
			dragOffset = 0
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @State var isPresented = true

	FriendRequestSuccessDrawer(
		friendUser: BaseUserDTO.danielAgapov,
		isPresented: $isPresented,
		onAddToActivityType: {}
	)
}

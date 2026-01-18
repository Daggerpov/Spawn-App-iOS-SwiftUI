import SwiftUI

/// A unified share drawer component matching the Figma design.
/// Used for sharing both profiles and activities.
struct ShareDrawer: View {
	let title: String
	@Binding var isPresented: Bool
	let onShareVia: () -> Void
	let onCopyLink: () -> Void
	let onWhatsApp: () -> Void
	let oniMessage: () -> Void

	@Environment(\.colorScheme) private var colorScheme
	@ObservedObject var themeService = ThemeService.shared

	// State for drag gesture
	@State private var dragOffset: CGFloat = 0

	// MARK: - Adaptive Colors

	private var adaptiveBackgroundColor: Color {
		universalBackgroundColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveOverlayColor: Color {
		switch colorScheme {
		case .dark: return Color.black.opacity(0.60)
		case .light: return Color.black.opacity(0.40)
		@unknown default: return Color.black.opacity(0.40)
		}
	}

	private var adaptiveTitleColor: Color {
		universalAccentColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveHandleColor: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.56, green: 0.52, blue: 0.52)
		case .light: return Color(red: 0.56, green: 0.52, blue: 0.52)
		@unknown default: return Color(red: 0.56, green: 0.52, blue: 0.52)
		}
	}

	/// Button background color (tertiary background from Figma: #e0dada light, darker for dark mode)
	private var adaptiveButtonBackgroundColor: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.35, green: 0.33, blue: 0.33)
		case .light: return Color(red: 0.88, green: 0.85, blue: 0.85)
		@unknown default: return Color(red: 0.88, green: 0.85, blue: 0.85)
		}
	}

	/// Button text color (secondary text from Figma: #262424)
	private var adaptiveButtonTextColor: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.82, green: 0.80, blue: 0.80)
		case .light: return Color(red: 0.15, green: 0.14, blue: 0.14)
		@unknown default: return Color(red: 0.15, green: 0.14, blue: 0.14)
		}
	}

	var body: some View {
		ZStack {
			// Background overlay
			if isPresented {
				adaptiveOverlayColor
					.ignoresSafeArea()
					.onTapGesture {
						withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
							isPresented = false
						}
					}
			}

			// Drawer content positioned at bottom
			VStack(spacing: 0) {
				Spacer()

				// Share drawer
				VStack(spacing: 0) {
					// Pull-down handle
					RoundedRectangle(cornerRadius: 100)
						.fill(adaptiveHandleColor)
						.frame(width: 50, height: 4)
						.padding(.top, 12)

					// Title
					Text(title)
						.font(.custom("Onest", size: 20).weight(.semibold))
						.foregroundColor(adaptiveTitleColor)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.top, 17)
						.padding(.horizontal, 29)

					// Share options
					HStack(spacing: 0) {
						// Share via button
						shareButton(
							action: {
								triggerHaptic()
								isPresented = false
								onShareVia()
							},
							icon: AnyView(
								ZStack {
									Circle()
										.fill(adaptiveButtonBackgroundColor)
										.frame(width: 64, height: 64)
									Image("share_via_button")
										.resizable()
										.renderingMode(.template)
										.foregroundColor(adaptiveButtonTextColor)
										.aspectRatio(contentMode: .fit)
										.frame(width: 24, height: 24)
								}
							),
							label: "Share via",
							width: 64
						)

						Spacer()

						// Copy Link button
						shareButton(
							action: {
								triggerHaptic()
								onCopyLink()
								Task { @MainActor in
									try? await Task.sleep(for: .seconds(0.1))
									isPresented = false
								}
							},
							icon: AnyView(
								ZStack {
									Circle()
										.fill(adaptiveButtonBackgroundColor)
										.frame(width: 64, height: 64)
									Image("copy_link_button")
										.resizable()
										.renderingMode(.template)
										.foregroundColor(adaptiveButtonTextColor)
										.aspectRatio(contentMode: .fit)
										.frame(width: 24, height: 24)
								}
							),
							label: "Copy Link",
							width: 68
						)

						Spacer()

						// WhatsApp button
						shareButton(
							action: {
								triggerHaptic()
								isPresented = false
								onWhatsApp()
							},
							icon: AnyView(
								Image("whatsapp_logo_for_sharing")
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(width: 64, height: 64)
									.clipShape(Circle())
							),
							label: "WhatsApp",
							width: 72
						)

						Spacer()

						// iMessage button
						shareButton(
							action: {
								triggerHaptic()
								isPresented = false
								oniMessage()
							},
							icon: AnyView(
								Image("imessage_for_sharing")
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(width: 64, height: 64)
									.clipShape(Circle())
							),
							label: "iMessage",
							width: 65
						)
					}
					.padding(.horizontal, 29)
					.padding(.top, 24)

					Spacer()

					// Home indicator
					RoundedRectangle(cornerRadius: 100)
						.fill(adaptiveHandleColor)
						.frame(width: 134, height: 5)
						.padding(.bottom, 8)
				}
				.frame(maxWidth: .infinity)
				.frame(height: 236)
				.background(adaptiveBackgroundColor)
				.cornerRadius(20, corners: [.topLeft, .topRight])
				.shadow(
					color: Color(red: 0, green: 0, blue: 0, opacity: 0.10),
					radius: 32
				)
				.offset(y: isPresented ? 0 : UIScreen.main.bounds.height)
				.offset(y: max(0, dragOffset))
				.gesture(
					DragGesture()
						.onChanged { value in
							// Only allow dragging down
							if value.translation.height > 0 {
								dragOffset = value.translation.height
							}
						}
						.onEnded { value in
							// If dragged down enough, dismiss
							if value.translation.height > 100 {
								withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
									isPresented = false
									dragOffset = 0
								}
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

	// MARK: - Share Button Component

	private func shareButton(
		action: @escaping () -> Void,
		icon: AnyView,
		label: String,
		width: CGFloat
	) -> some View {
		Button(action: action) {
			VStack(spacing: 8) {
				icon
				Text(label)
					.font(.system(size: 16, weight: .regular))
					.foregroundColor(adaptiveButtonTextColor)
			}
			.frame(width: width)
		}
	}

	private func triggerHaptic() {
		let impactGenerator = UIImpactFeedbackGenerator(style: .light)
		impactGenerator.impactOccurred()
	}
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
	@Previewable @State var showShareSheet: Bool = true

	ZStack {
		Color.black.ignoresSafeArea()

		VStack {
			Button("Toggle Share Sheet") {
				showShareSheet.toggle()
			}
			.padding()
			.background(Color.blue)
			.foregroundColor(.white)
			.cornerRadius(10)

			Spacer()
		}
		.padding()

		ShareDrawer(
			title: "Share this Spawn",
			isPresented: $showShareSheet,
			onShareVia: { print("Share via tapped") },
			onCopyLink: { print("Copy link tapped") },
			onWhatsApp: { print("WhatsApp tapped") },
			oniMessage: { print("iMessage tapped") }
		)
	}
}

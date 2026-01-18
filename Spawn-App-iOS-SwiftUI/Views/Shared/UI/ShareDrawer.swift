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

	/// Overlay background color (matching Figma: 60% white for light, 60% black for dark)
	/// This is used on top of the blur material
	private var adaptiveOverlayColor: Color {
		switch colorScheme {
		case .dark: return Color.black.opacity(0.40)
		case .light: return Color.white.opacity(0.40)
		@unknown default: return Color.white.opacity(0.40)
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
			// Background overlay with blur - covers entire screen including tab bar
			// Matching Figma design: backdrop-blur with semi-transparent overlay
			if isPresented {
				// Blur layer (backdrop-blur-[4px] equivalent)
				Rectangle()
					.fill(.ultraThinMaterial)
					.ignoresSafeArea(.all)

				// Color tint on top of blur (matching Figma's transparent overlay)
				adaptiveOverlayColor
					.ignoresSafeArea(.all)
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
										.frame(width: 28, height: 28)
								}
							),
							label: "Share"
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
										.frame(width: 28, height: 28)
								}
							),
							label: "Copy"
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
							label: "WhatsApp"
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
							label: "iMessage"
						)
					}
					.padding(.horizontal, 24)
					.padding(.top, 24)
					.padding(.bottom, 24)
				}
				.frame(maxWidth: .infinity)
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
			.ignoresSafeArea(.all)
		}
		.animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
	}

	// MARK: - Share Button Component

	private func shareButton(
		action: @escaping () -> Void,
		icon: AnyView,
		label: String
	) -> some View {
		Button(action: action) {
			VStack(spacing: 8) {
				icon
				Text(label)
					.font(.system(size: 14, weight: .regular))
					.foregroundColor(adaptiveButtonTextColor)
					.lineLimit(1)
					.minimumScaleFactor(0.8)
			}
			.frame(minWidth: 64)
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

import SwiftUI

struct ProfileShareDrawer: View {
	let user: Nameable
	@Binding var showShareSheet: Bool

	var body: some View {
		ShareDrawer(
			title: "Share Profile",
			isPresented: $showShareSheet,
			onShareVia: shareViaSystem,
			onCopyLink: shareViaLink,
			onWhatsApp: shareViaWhatsApp,
			oniMessage: shareViaSMS
		)
	}

	// MARK: - Share Functions
	private func shareViaSystem() {
		let userName = FormatterService.shared.formatName(user: user)
		generateShareURL(for: user) { profileURL in
			Task { @MainActor in
				let shareText =
					"Check out \(userName)'s profile on Spawn! \(profileURL.absoluteString)"

				let activityVC = UIActivityViewController(
					activityItems: [shareText],
					applicationActivities: nil
				)

				if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
					let window = windowScene.windows.first
				{

					var topController = window.rootViewController
					while let presentedViewController = topController?.presentedViewController {
						topController = presentedViewController
					}

					if let popover = activityVC.popoverPresentationController {
						popover.sourceView = topController?.view
						popover.sourceRect = topController?.view.bounds ?? CGRect.zero
					}

					topController?.present(activityVC, animated: true, completion: nil)
				}
			}
		}
	}

	private func shareViaLink() {
		generateShareURL(for: user) { url in
			UIPasteboard.general.string = url.absoluteString

			// Show success notification
			Task { @MainActor in
				try? await Task.sleep(for: .seconds(0.2))
				InAppNotificationManager.shared.showNotification(
					title: "Link copied to clipboard",
					message: "Profile link has been copied to your clipboard",
					type: .success,
					duration: 5.0
				)
			}
		}
	}

	private func shareViaWhatsApp() {
		let userName = FormatterService.shared.formatName(user: user)
		generateShareURL(for: user) { url in
			Task { @MainActor in
				let shareText =
					"Check out \(userName)'s profile on Spawn! \(url.absoluteString)"

				if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
					let whatsappURL = URL(string: "whatsapp://send?text=\(encodedText)")
				{

					if UIApplication.shared.canOpenURL(whatsappURL) {
						UIApplication.shared.open(whatsappURL)
					} else {
						print("WhatsApp not installed or URL scheme not supported")
					}
				}
			}
		}
	}

	private func shareViaSMS() {
		let userName = FormatterService.shared.formatName(user: user)
		generateShareURL(for: user) { url in
			Task { @MainActor in
				let shareText =
					"Check out \(userName)'s profile on Spawn! \(url.absoluteString)"

				if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
					let smsURL = URL(string: "sms:?body=\(encodedText)")
				{

					if UIApplication.shared.canOpenURL(smsURL) {
						UIApplication.shared.open(smsURL)
					} else {
						print("SMS not available")
					}
				}
			}
		}
	}

	private func generateShareURL(for user: Nameable, completion: @Sendable @escaping (URL) -> Void) {
		// Use the centralized Constants for share URL generation with share codes
		ServiceConstants.generateProfileShareCodeURL(for: user.id) { url in
			completion(url ?? ServiceConstants.generateProfileShareURL(for: user.id))
		}
	}
}

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

		ProfileShareDrawer(
			user: BaseUserDTO.danielAgapov,
			showShareSheet: $showShareSheet
		)
	}
}

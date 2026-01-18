import SwiftUI

struct ActivityShareDrawer: View {
	let activity: FullFeedActivityDTO
	@Binding var showShareSheet: Bool

	private var activityTitle: String {
		return activity.title ?? "Activity"
	}

	var body: some View {
		ShareDrawer(
			title: "Share this Spawn",
			isPresented: $showShareSheet,
			onShareVia: shareViaSystem,
			onCopyLink: shareViaLink,
			onWhatsApp: shareViaWhatsApp,
			oniMessage: shareViaSMS
		)
	}

	// MARK: - Share Functions
	private func shareViaSystem() {
		let title = activityTitle
		generateShareURL(for: activity) { activityURL in
			Task { @MainActor in
				let shareText = "Join me for \"\(title)\"! \(activityURL.absoluteString)"

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
		generateShareURL(for: activity) { url in
			UIPasteboard.general.string = url.absoluteString

			// Show success notification
			Task { @MainActor in
				try? await Task.sleep(for: .seconds(0.2))
				InAppNotificationManager.shared.showNotification(
					title: "Link copied to clipboard",
					message: "Activity link has been copied to your clipboard",
					type: .success,
					duration: 5.0
				)
			}
		}
	}

	private func shareViaWhatsApp() {
		let title = activityTitle
		generateShareURL(for: activity) { url in
			Task { @MainActor in
				let shareText = "Join me for \"\(title)\"! \(url.absoluteString)"

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
		// Use the SMS sharing service with enhanced messaging
		SMSShareService.shared.shareActivity(activity)
	}

	private func generateShareURL(for activity: FullFeedActivityDTO, completion: @Sendable @escaping (URL) -> Void) {
		// Use the centralized Constants for share URL generation with share codes
		ServiceConstants.generateActivityShareCodeURL(for: activity.id) { url in
			completion(url ?? ServiceConstants.generateActivityShareURL(for: activity.id))
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

		ActivityShareDrawer(
			activity: .mockDinnerActivity,
			showShareSheet: $showShareSheet
		)
	}
}

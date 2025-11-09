import Foundation
import UIKit

struct NotificationIconExporter {
	static func exportAppIconForNotifications() {
		// First try to use the SpawnLogo from assets
		if let image = UIImage(named: "SpawnLogo") ?? UIImage(named: "Spawn_Glow") {
			exportImage(image, filename: "app_logo.png")
			return
		}

		// Fallback to app icon
		if let appIcon = UIApplication.shared.icon {
			exportImage(appIcon, filename: "app_logo.png")
			return
		}

		print("Failed to export app icon for notifications")
	}

	private static func exportImage(_ image: UIImage, filename: String) {
		let fileManager = FileManager.default
		let tempDirectory = fileManager.temporaryDirectory
		let fileURL = tempDirectory.appendingPathComponent(filename)

		// Resize image to proper size for notifications
		let size = CGSize(width: 100, height: 100)
		if let resizedImage = image.resize(to: size),
			let pngData = resizedImage.pngData()
		{
			do {
				try pngData.write(to: fileURL)
			} catch {
				print("Failed to write app icon: \(error.localizedDescription)")
			}
		}
	}
}

// Extension to get app icon
extension UIApplication {
	var icon: UIImage? {
		guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
			let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
			let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
			let lastIcon = iconFiles.last
		else {
			return nil
		}

		return UIImage(named: lastIcon)
	}
}

// Extension to resize UIImage
extension UIImage {
	func resize(to size: CGSize) -> UIImage? {
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		defer { UIGraphicsEndImageContext() }

		draw(in: CGRect(origin: .zero, size: size))

		return UIGraphicsGetImageFromCurrentImageContext()
	}
}

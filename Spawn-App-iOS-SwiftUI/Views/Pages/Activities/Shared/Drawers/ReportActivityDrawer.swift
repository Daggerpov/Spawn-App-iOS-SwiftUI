import SwiftUI

struct ReportActivityDrawer: View {
	@Environment(\.dismiss) private var dismiss
	let activity: FullFeedActivityDTO
	let onReport: (ReportType, String) -> Void

	@State private var selectedReportType: ReportType? = nil
	@State private var reportDescription: String = ""
	@State private var showConfirmation: Bool = false
	@State private var isSubmitting: Bool = false

	private var activityTitle: String {
		activity.title ?? "Activity"
	}

	private var creatorName: String {
		activity.creatorUser.name ?? activity.creatorUser.username ?? "User"
	}

	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				// Header
				headerView

				// Content
				if selectedReportType == nil {
					// Initial report type selection
					reportTypeSelectionView
				} else {
					// Confirmation and description view
					confirmationView
				}

				Spacer()
			}
			.background(Color(.systemBackground))
			.navigationBarHidden(true)
		}
		.interactiveDismissDisabled(isSubmitting)
	}

	private var headerView: some View {
		HStack {
			Button(action: {
				if selectedReportType != nil {
					selectedReportType = nil
				} else {
					dismiss()
				}
			}) {
				Image(systemName: selectedReportType != nil ? "chevron.left" : "xmark")
					.foregroundColor(.primary)
					.font(.system(size: 16, weight: .medium))
			}

			Spacer()

			Text("Report Activity")
				.font(.headline)
				.fontWeight(.semibold)

			Spacer()

			// Invisible placeholder for alignment
			Color.clear.frame(width: 24, height: 24)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
	}

	private var reportTypeSelectionView: some View {
		VStack(spacing: 0) {
			// Title
			VStack(spacing: 8) {
				Text("Why are you reporting this activity?")
					.font(.title2)
					.fontWeight(.semibold)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
					.padding(.top, 24)

				Text("Activity: \"\(activityTitle)\" by \(creatorName)")
					.font(.subheadline)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
					.padding(.bottom, 24)
			}

			// Report type options
			VStack(spacing: 0) {
				ForEach(ReportType.allCases, id: \.self) { reportType in
					reportTypeRow(reportType: reportType)

					if reportType != ReportType.allCases.last {
						Divider()
							.padding(.leading, 16)
					}
				}
			}
			.background(Color(.systemBackground))
			.cornerRadius(12)
			.padding(.horizontal, 16)

			// Footer info
			VStack(spacing: 8) {
				Text("This report will be reviewed by our moderation team")
					.font(.caption)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
					.padding(.top, 24)
			}
		}
	}

	private var confirmationView: some View {
		VStack(spacing: 0) {
			// Confirmation header
			VStack(spacing: 12) {
				Text("Report \"\(activityTitle)\"")
					.font(.title2)
					.fontWeight(.semibold)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
					.padding(.top, 24)

				if let reportType = selectedReportType {
					Text("for \(reportType.displayName)")
						.font(.headline)
						.foregroundColor(.red)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 16)
				}
			}

			// Description input
			VStack(alignment: .leading, spacing: 8) {
				Text("Additional details (optional)")
					.font(.headline)
					.padding(.horizontal, 16)
					.padding(.top, 32)

				TextEditor(text: $reportDescription)
					.frame(minHeight: 100)
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(Color(.systemGray6))
					.cornerRadius(8)
					.padding(.horizontal, 16)

				Text("Help us understand what happened")
					.font(.caption)
					.foregroundColor(.secondary)
					.padding(.horizontal, 16)
			}

			// Submit button
			VStack(spacing: 16) {
				Button(action: submitReport) {
					HStack {
						if isSubmitting {
							ProgressView()
								.progressViewStyle(CircularProgressViewStyle(tint: .white))
								.scaleEffect(0.8)
						}

						Text(isSubmitting ? "Submitting..." : "Submit Report")
							.font(.headline)
							.foregroundColor(.white)
					}
					.frame(maxWidth: .infinity)
					.frame(height: 50)
					.background(Color.red)
					.cornerRadius(12)
				}
				.disabled(isSubmitting)
				.padding(.horizontal, 16)
				.padding(.top, 32)
			}

			// Footer info
			VStack(spacing: 8) {
				Text("This report will be reviewed by our moderation team")
					.font(.caption)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
					.padding(.top, 16)
			}
		}
	}

	private func reportTypeRow(reportType: ReportType) -> some View {
		Button(action: {
			selectedReportType = reportType
		}) {
			HStack {
				Text(reportType.displayName)
					.font(.system(size: 16, weight: .medium))
					.foregroundColor(.primary)
					.multilineTextAlignment(.leading)

				Spacer()

				Image(systemName: "chevron.right")
					.font(.system(size: 14, weight: .medium))
					.foregroundColor(.secondary)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 16)
			.background(Color(.systemBackground))
		}
		.buttonStyle(PlainButtonStyle())
	}

	private func submitReport() {
		guard let reportType = selectedReportType else { return }

		isSubmitting = true

		// Add a small delay to show the loading state
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			let description = reportDescription.isEmpty ? "No additional details provided" : reportDescription
			onReport(reportType, description)
			isSubmitting = false
			dismiss()
		}
	}
}

struct ReportActivityDrawer_Previews: PreviewProvider {
	static var previews: some View {
		ReportActivityDrawer(
			activity: FullFeedActivityDTO.mockDinnerActivity,
			onReport: { _, _ in }
		)
	}
}

import SwiftUI

struct ReportUserDrawer: View {
	@Environment(\.dismiss) private var dismiss
	let user: Nameable
	let onReport: (ReportType, String) -> Void

	@State private var selectedReportType: ReportType? = nil
	@State private var reportDescription: String = ""
	@State private var showConfirmation: Bool = false
	@State private var isSubmitting: Bool = false

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
		VStack(spacing: 0) {
			// Handle bar
			RoundedRectangle(cornerRadius: 2)
				.fill(Color(.systemGray4))
				.frame(width: 36, height: 4)
				.padding(.top, 8)

			// Header content
			HStack {
				if selectedReportType != nil {
					Button("Back") {
						selectedReportType = nil
					}
					.foregroundColor(.primary)
					.disabled(isSubmitting)
				}

				Spacer()

				if selectedReportType != nil {
					Button("Submit") {
						submitReport()
					}
					.foregroundColor(.red)
					.disabled(isSubmitting)
				}
			}
			.padding(.horizontal, 16)
			.padding(.top, 16)
			.padding(.bottom, 8)

			if selectedReportType != nil {
				Divider()
			}
		}
	}

	private var reportTypeSelectionView: some View {
		VStack(spacing: 0) {
			// Title
			VStack(spacing: 8) {
				Text("Why are you reporting this user?")
					.font(.title2)
					.fontWeight(.semibold)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
					.padding(.top, 24)
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
		}
	}

	private var confirmationView: some View {
		VStack(spacing: 0) {
			// Title
			VStack(spacing: 8) {
				Text("Report \(FormatterService.shared.formatName(user: user))")
					.font(.title2)
					.fontWeight(.semibold)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
					.padding(.top, 24)

				if let selectedType = selectedReportType {
					Text("Reason: \(selectedType.displayName)")
						.font(.subheadline)
						.foregroundColor(.secondary)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 16)
						.padding(.bottom, 16)
				}
			}

			// Description input
			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Text("Additional details (optional)")
						.font(.subheadline)
						.fontWeight(.medium)
						.foregroundColor(.primary)
					Spacer()
				}
				.padding(.horizontal, 16)

				TextField("Provide additional context...", text: $reportDescription, axis: .vertical)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.lineLimit(3...6)
					.disabled(isSubmitting)
					.padding(.horizontal, 16)
			}
			.padding(.bottom, 24)

			// Info text
			VStack(spacing: 8) {
				Text("This report will be reviewed by our moderation team")
					.font(.caption)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 16)
			}
			.padding(.bottom, 16)
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

struct ReportUserDrawer_Previews: PreviewProvider {
	static var previews: some View {
		ReportUserDrawer(
			user: BaseUserDTO.danielAgapov,
			onReport: { _, _ in }
		)
	}
}

import SwiftUI

struct ReportRow: View {
	let report: FetchReportedContentDTO

	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Image(systemName: iconForReportType(report.reportType))
						.foregroundColor(colorForReportType(report.reportType))
						.font(.system(size: 16))

					Text(report.reportType.displayName)
						.font(.headline)
						.foregroundColor(.primary)

					Spacer()

					Text(report.timeReported, style: .date)
						.font(.caption)
						.foregroundColor(.secondary)
				}

				Text(report.contentType.description)
					.font(.subheadline)
					.foregroundColor(.secondary)

				if !report.description.isEmpty && report.description != "No description provided" {
					Text(report.description)
						.font(.body)
						.foregroundColor(.primary)
						.lineLimit(3)
				}

				HStack {
					Text("Status:")
						.font(.caption)
						.foregroundColor(.secondary)

					Text(report.resolution.rawValue.capitalized)
						.font(.caption)
						.fontWeight(.semibold)
						.foregroundColor(colorForResolution(report.resolution))

					Spacer()
				}
			}

			Spacer()
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
	}

	private func iconForReportType(_ reportType: ReportType) -> String {
		switch reportType {
		case .harassment:
			return "person.2.badge.minus"
		case .violence:
			return "exclamationmark.triangle.fill"
		case .nudity:
			return "eye.slash"
		case .bullying:
			return "person.crop.circle.badge.xmark"
		}
	}

	private func colorForReportType(_ reportType: ReportType) -> Color {
		switch reportType {
		case .harassment:
			return .orange
		case .violence:
			return .red
		case .nudity:
			return .purple
		case .bullying:
			return .pink
		}
	}

	private func colorForResolution(_ resolution: ResolutionStatus) -> Color {
		switch resolution {
		case .pending:
			return .orange
		case .resolved:
			return .green
		case .dismissed:
			return .gray
		}
	}
}

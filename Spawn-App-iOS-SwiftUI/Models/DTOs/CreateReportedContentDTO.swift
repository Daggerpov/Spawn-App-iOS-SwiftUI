import Foundation

struct CreateReportedContentDTO: Codable {
	let reporterUserId: UUID
	let contentId: UUID
	let contentType: EntityType
	let reportType: ReportType
	let description: String

	// Convenience initializer for creating reports
	init(
		reporterUserId: UUID,
		contentId: UUID,
		contentType: EntityType,
		reportType: ReportType,
		description: String
	) {
		self.reporterUserId = reporterUserId
		self.contentId = contentId
		self.contentType = contentType
		self.reportType = reportType
		self.description = description
	}
}

import Foundation

struct FetchReportedContentDTO: Codable, Identifiable, Sendable {
	let id: UUID
	let reporterUserId: UUID?
	let reporterUsername: String?
	let contentId: UUID
	let contentType: EntityType
	let timeReported: Date
	let resolution: ResolutionStatus
	let reportType: ReportType
	let description: String
	let reportedUserId: UUID?
	let reportedUsername: String?
}

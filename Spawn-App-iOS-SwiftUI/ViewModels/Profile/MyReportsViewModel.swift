import Foundation
import SwiftUI

@MainActor
class MyReportsViewModel: ObservableObject {
	@Published var reports: [FetchReportedContentDTO] = []
	@Published var isLoading = false
	@Published var errorMessage: String?

	private let reportingService: ReportingService

	init(reportingService: ReportingService = ReportingService()) {
		self.reportingService = reportingService
	}

	func loadReports(for userId: UUID) async {
		isLoading = true
		errorMessage = nil

		do {
			reports = try await reportingService.getReportsByUser(reporterId: userId)
		} catch let error as APIError {
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
			reports = []
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)
			reports = []
		}

		isLoading = false
	}
}

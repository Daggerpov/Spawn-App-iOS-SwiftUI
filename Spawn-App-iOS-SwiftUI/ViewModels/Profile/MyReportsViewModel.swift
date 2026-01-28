import SwiftUI

@Observable
@MainActor
final class MyReportsViewModel {
	var reports: [FetchReportedContentDTO] = []
	var isLoading = false
	var errorMessage: String?

	private let reportingService: ReportingService
	private let errorNotificationService = ErrorNotificationService.shared

	init(reportingService: ReportingService = ReportingService()) {
		self.reportingService = reportingService
	}

	func loadReports(for userId: UUID) async {
		isLoading = true
		errorMessage = nil

		do {
			reports = try await reportingService.getReportsByUser(reporterId: userId)
		} catch let error as APIError {
			errorMessage = errorNotificationService.handleError(
				error, resource: .report, operation: .fetch)
			reports = []
		} catch {
			errorMessage = errorNotificationService.handleError(
				error, resource: .report, operation: .fetch)
			reports = []
		}

		isLoading = false
	}
}

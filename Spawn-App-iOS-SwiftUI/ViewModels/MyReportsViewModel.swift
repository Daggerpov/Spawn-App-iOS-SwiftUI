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
        } catch {
            errorMessage = "Failed to load reports: \(error.localizedDescription)"
            reports = []
        }
        
        isLoading = false
    }
} 

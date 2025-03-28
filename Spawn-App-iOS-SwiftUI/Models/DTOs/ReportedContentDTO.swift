import Foundation

enum ReportType: String, Codable {
    case BULLYING
    case VIOLENCE_HATE_EXPLOITATION
    case FALSE_INFORMATION
}

enum EntityType: String, Codable {
    case ChatMessage
    case User
    case Event
}

enum ResolutionStatus: String, Codable {
    case PENDING
    case CONTENT_REMOVED
    case IGNORED
    case BANNED_USER
}

struct ReportedContentDTO: Codable, Identifiable {
    var id: UUID?
    var reportType: ReportType
    var contentType: EntityType
    var contentId: UUID
    var contentOwnerId: UUID
    var reporterId: UUID
    var description: String?
    var timestamp: Date?
    var resolutionStatus: ResolutionStatus?
    
    init(reportType: ReportType, contentType: EntityType, contentId: UUID, contentOwnerId: UUID, reporterId: UUID, description: String? = nil) {
        self.reportType = reportType
        self.contentType = contentType
        self.contentId = contentId
        self.contentOwnerId = contentOwnerId
        self.reporterId = reporterId
        self.description = description
        self.resolutionStatus = .PENDING
    }
} 
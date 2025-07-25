import SwiftUI

struct ActivityCardView: View {
    @ObservedObject var viewModel: ActivityCardViewModel
    @ObservedObject var activity: FullFeedActivityDTO
    @ObservedObject var locationManager: LocationManager
    var color: Color
    var callback: (FullFeedActivityDTO, Color) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    // State for delete confirmation dialog
    @State private var showDeleteConfirmation = false
    
    // State for activity reporting
    @State private var showActivityMenu: Bool = false
    @State private var showReportDialog: Bool = false
    @StateObject private var userAuth = UserAuthViewModel.shared
    
    init(
        userId: UUID, activity: FullFeedActivityDTO, color: Color,
        locationManager: LocationManager,
        callback: @escaping (FullFeedActivityDTO, Color) -> Void,
        selectedTab: Binding<TabType?> = .constant(nil)
    ) {
        self.activity = activity
        self.color = color
        self.locationManager = locationManager
        self.viewModel = ActivityCardViewModel(
            apiService: MockAPIService.isMocking
                ? MockAPIService(userId: userId) : APIService(), userId: userId,
            activity: activity)
        self.callback = callback
        self._selectedTab = selectedTab
        
    }
    
    // Use the same color for both light and dark modes
    private var cardBackgroundColor: Color {
        return color
    }
    
    // Border color for better definition in dark mode
    private var cardBorderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.1)
        case .light:
            return Color.clear
        @unknown default:
            return Color.clear
        }
    }
    
    // Shadow configuration for different modes
    private var shadowColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.3)
        case .light:
            return Color.black.opacity(0.10)
        @unknown default:
            return Color.black.opacity(0.10)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Row: Title, Participants
                ActivityCardTopRowView(activity: activity, selectedTab: $selectedTab, locationManager: locationManager)
                // Location Row
                ActivityLocationView(activity: activity, locationManager: locationManager)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(cardBorderColor, lineWidth: 1)
                    )
            )
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            .onAppear {
                viewModel.fetchIsParticipating()
            }
            .onChange(of: activity.participationStatus) { _ in
                // Refresh participation status when the activity's participation status changes
                viewModel.updateActivity(activity)
            }
            .onTapGesture {
                callback(activity, color)
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // Only allow reporting other users' activities
                if viewModel.userId != activity.creatorUser.id {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showActivityMenu = true
                }
            }
            .contextMenu {
                // Only show delete option if the current user is the creator of the activity
                if viewModel.userId == activity.creatorUser.id {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showActivityMenu) {
                ActivityMenuView(
                    activity: activity,
                    showReportDialog: $showReportDialog
                )
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showReportDialog) {
                ReportActivityDrawer(
                    activity: activity,
                    onReport: { reportType, description in
                        Task {
                            await reportActivity(reportType: reportType, description: description)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .alert("Delete Activity", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteActivity()
                        } catch {
                            print("Failed to delete activity: \(error.localizedDescription)")
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this activity? This action cannot be undone.")
            }

            // Time Status Badge
            ActivityStatusView(activity: activity)
        }
    }
    
    private func reportActivity(reportType: ReportType, description: String) async {
        guard let currentUserId = userAuth.spawnUser?.id else { return }
        
        await viewModel.reportActivity(
            reporterUserId: currentUserId,
            reportType: reportType,
            description: description
        )
    }
}

extension Color {
    var components: (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let uiColor = UIColor(self)
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}

#Preview {
    let mockUserId: UUID = UUID()
    ActivityCardView(
        userId: mockUserId,
        activity: .mockDinnerActivity,
        color: figmaSoftBlue,
        locationManager: LocationManager(),
        callback: { event, color in
            print("Event tapped: \(event.title ?? "Untitled")")
        }
    )
}

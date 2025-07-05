import SwiftUI

struct MyReportsView: View {
    @StateObject private var viewModel = MyReportsViewModel()
    @StateObject var userAuth = UserAuthViewModel.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading reports...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.reports.isEmpty {
                    emptyStateView
                } else {
                    reportsList
                }
            }
            .navigationTitle("My Reports")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: cancelButton)
            .onAppear {
                loadReports()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var cancelButton: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("All Good!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Looks like you haven't found anything to report...yet. Thank you for helping keep our community safe.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var reportsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.reports, id: \.id) { report in
                    ReportRow(report: report)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .refreshable {
            await loadReportsAsync()
        }
    }
    
    private func loadReports() {
        Task {
            await loadReportsAsync()
        }
    }
    
    private func loadReportsAsync() async {
        guard let currentUserId = userAuth.spawnUser?.id else { return }
        await viewModel.loadReports(for: currentUserId)
    }
}

struct ReportRow: View {
    let report: ReportedContentDTO
    
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
                    
                    if let timeReported = report.timeReported {
                        Text(timeReported, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                    
                    Text(report.resolution?.rawValue.capitalized ?? "Pending")
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
    
    private func colorForResolution(_ resolution: ResolutionStatus?) -> Color {
        switch resolution {
        case .pending:
            return .orange
        case .resolved:
            return .green
        case .dismissed:
            return .gray
        case .none:
            return .orange
        }
    }
}

#Preview {
    MyReportsView()
} 
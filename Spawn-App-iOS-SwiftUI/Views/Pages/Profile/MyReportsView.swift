import SwiftUI

struct MyReportsView: View {
    @StateObject private var viewModel = MyReportsViewModel()
    @StateObject var userAuth = UserAuthViewModel.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
                
                Spacer()
                
                Text("My Reports")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                // Empty view for balance
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Content
            if viewModel.isLoading {
                ProgressView("Loading reports...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.reports.isEmpty {
                emptyStateView
            } else {
                reportsList
            }
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .onAppear {
            loadReports()
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

#Preview {
    MyReportsView()
}

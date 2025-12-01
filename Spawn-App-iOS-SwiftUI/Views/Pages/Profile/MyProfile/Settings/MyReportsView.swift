import SwiftUI

struct MyReportsView: View {
	@StateObject private var viewModel = MyReportsViewModel()
	@ObservedObject var userAuth = UserAuthViewModel.shared
	@Environment(\.presentationMode) var presentationMode

	var body: some View {
		VStack(spacing: 0) {
			// Header - using UnifiedNavigationHeader
			UnifiedNavigationHeader.withTitle("My Reports")

			// Content
			if viewModel.isLoading {
				LoadingStateView(message: "Loading reports...")
			} else if viewModel.reports.isEmpty {
				EmptyStateView.allGood()
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

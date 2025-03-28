import SwiftUI

struct ChatMessageReportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatMessageActionViewModel
    let chatMessage: FullEventChatMessageDTO
    @State private var selectedReportType: ReportType?
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("D")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                
                Text("Why are you reporting this comment?")
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Your report is anonymous")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            .padding(.top, 12)
            
            // Report options
            VStack(spacing: 0) {
                reportOptionButton(.BULLYING, label: "Bullying")
                
                Divider()
                
                reportOptionButton(.VIOLENCE_HATE_EXPLOITATION, label: "Violence, hate or exploitation")
                
                Divider()
                
                reportOptionButton(.FALSE_INFORMATION, label: "False Information")
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .alert("Report Submitted", isPresented: $showConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your report. We'll review this content.")
        }
    }
    
    private func reportOptionButton(_ type: ReportType, label: String) -> some View {
        Button(action: {
            selectedReportType = type
            submitReport(type: type)
        }) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
    }
    
    private func submitReport(type: ReportType) {
        isSubmitting = true
        
        Task {
            await viewModel.reportMessage(chatMessage: chatMessage, reportType: type)
            
            await MainActor.run {
                isSubmitting = false
                showConfirmation = true
            }
        }
    }
}

// Preview disabled to avoid error since it requires a real ViewModel and ChatMessage
// #Preview {
//     ChatMessageReportView(viewModel: ChatMessageActionViewModel(...), chatMessage: ...)
// } 
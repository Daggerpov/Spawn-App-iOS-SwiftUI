import SwiftUI

struct ChatMessageActionMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatMessageActionViewModel
    let chatMessage: FullEventChatMessageDTO
    @State private var showReportView = false
    @State private var isBlocked = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Like button
            Button {
                Task {
                    await viewModel.toggleLike(for: chatMessage)
                    dismiss()
                }
            } label: {
                Label(viewModel.isLiked ? "Unlike" : "Like", systemImage: viewModel.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.isLiked ? .red : .black)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            
            Divider()
            
            // Block button
            Button(action: {
                dismiss()
                isBlocked.toggle()
                // In a real app, you would implement the block functionality here
            }) {
                HStack {
                    Text("Block")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
            }
            
            Divider()
            
            // Report button
            Button(action: {
                dismiss()
                showReportView = true
            }) {
                HStack {
                    Text("Report")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Image(systemName: "flag")
                        .foregroundColor(.red)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showReportView) {
            ChatMessageReportView(viewModel: viewModel, chatMessage: chatMessage)
        }
    }
}

// Preview disabled to avoid error since it requires a real ViewModel and ChatMessage
// #Preview {
//     ChatMessageActionMenuView(viewModel: ChatMessageActionViewModel(...), chatMessage: ...)
// } 

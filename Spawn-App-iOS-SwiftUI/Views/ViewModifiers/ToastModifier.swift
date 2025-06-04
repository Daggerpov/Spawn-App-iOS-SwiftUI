import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    HStack {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.8))
                            )
                    }
                    .padding(.top, 30)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
                    
                    Spacer()
                }
                .zIndex(100)
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, duration: Double = 2.0) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, duration: duration))
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var showToast = false
    
    VStack(spacing: 20) {
        Button("Show Toast") {
            withAnimation {
                showToast = true
            }
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        
        Text("This is the main content")
            .padding()
    }
    .toast(isShowing: $showToast, message: "This is a toast message!", duration: 3.0)
} 
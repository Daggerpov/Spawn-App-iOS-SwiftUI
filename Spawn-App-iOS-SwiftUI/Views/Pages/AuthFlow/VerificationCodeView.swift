import SwiftUI

struct VerificationCodeView: View {
    @ObservedObject var viewModel: UserAuthViewModel
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var timer: Timer? = nil
    @State private var secondsRemaining: Int = 30
    @State private var isResendEnabled: Bool = false
    @Environment(\.dismiss) var dismiss
    
    private var isFormValid: Bool {
        code.allSatisfy { $0.count == 1 && $0.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil }
    }
    
    private var codeString: String {
        code.joined()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: {
                        // Back action
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Main Content
                VStack(spacing: 32) {
                    // Title and Subtitle
                    VStack(spacing: 16) {
                        Text("Verify Your Email")
                            .font(heading1)
                            .foregroundColor(.primary)
                        Text("We've sent a 6-digit code to " + (viewModel.email ?? "your email"))
                            .font(.onestRegular(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    
                    // Form Fields
                    VStack(spacing: 24) {
                        // Verification Code Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verification Code")
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.primary)
                            HStack(spacing: 12) {
                                ForEach(0..<6, id: \ .self) { idx in
                                    ZStack {
                                        Rectangle()
                                            .fill(viewModel.errorMessage != nil ? Color.red.opacity(0.1) : figmaAuthButtonGrey)
                                            .frame(width: 48, height: 56)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(viewModel.errorMessage != nil ? Color.red : Color.clear, lineWidth: 2)
                                            )
                                        TextField("", text: Binding(
                                            get: { code[idx] },
                                            set: { newValue in
                                                if newValue.count <= 1 && (newValue.isEmpty || newValue.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil) {
                                                    code[idx] = newValue
                                                    if !newValue.isEmpty && idx < 5 {
                                                        focusedIndex = idx + 1
                                                    }
                                                }
                                            }
                                        ))
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.onestRegular(size: 24))
                                        .frame(width: 48, height: 56)
                                        .focused($focusedIndex, equals: idx)
                                    }
                                }
                            }
                        }
                        
                        // Verify Button
                        Button(action: {
                            Task {
                                if let email = viewModel.email {
                                    await viewModel.verifyEmailCode(email: email, code: codeString)
                                }
                            }
                        }) {
                            OnboardingButtonCoreView("Verify") {
                                isFormValid ? figmaIndigo : Color.gray.opacity(0.6)
                            }
                        }
                        .padding(.top, -16)
                        .padding(.bottom, -30)
                        .padding(.horizontal, -22)
                        .disabled(!isFormValid)
                    }
                    .padding(.horizontal, 40)
                    
                    // Resend Code
                    HStack(spacing: 4) {
                        Text("Didn't get it?")
                            .font(.onestRegular(size: 16))
                        Button(action: {
                            resendCode()
                        }) {
                            Text("Resend code")
                                .underline()
                                .font(.onestRegular(size: 16))
                                .foregroundColor(isResendEnabled ? figmaIndigo : .secondary)
                        }
                        .disabled(!isResendEnabled)
                        Text("in \(String(format: "%02d", secondsRemaining))")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(.secondary)
                            .opacity(isResendEnabled ? 0 : 1)
                    }
                    .padding(.top, 8)
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationDestination(isPresented: $viewModel.shouldNavigateToUserDetailsView, destination: {UserDetailsInputView()})
            .onAppear {
                startTimer()
                focusedIndex = 0
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .navigationBarHidden(true)
    }
    
    private func startTimer() {
        secondsRemaining = viewModel.secondsUntilNextVerificationAttempt
        isResendEnabled = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            }
            if secondsRemaining == 0 {
                isResendEnabled = true
                timer?.invalidate()
            }
        }
    }
    
    private func resendCode() {
        Task {
            if let email = viewModel.email {
                await viewModel.sendEmailVerification(email: email)
                // The timer will be updated with the new seconds from the backend response
                await MainActor.run {
                    startTimer()
                }
            }
        }
    }
}

#Preview {
    VerificationCodeView(viewModel: UserAuthViewModel.shared)
} 

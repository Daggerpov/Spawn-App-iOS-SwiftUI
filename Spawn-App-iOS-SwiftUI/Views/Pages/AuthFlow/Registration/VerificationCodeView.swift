import SwiftUI

struct VerificationCodeView: View {
    @ObservedObject var viewModel: UserAuthViewModel
    @State private var code: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var timer: Timer? = nil
    @State private var secondsRemaining: Int = 30
    @State private var isResendEnabled: Bool = false
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var isFormValid: Bool {
        code.allSatisfy { $0.count == 1 && $0.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil }
    }
    
    private var codeString: String {
        code.joined()
    }
    
    private var inputBackgroundColor: Color {
        if viewModel.errorMessage != nil {
            return Color.red.opacity(0.1)
        }
        return colorScheme == .dark ? Color(hex: "#2C2C2C") : Color(hex: "#F5F5F5")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Spacer()
            mainContent
            Spacer()
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .navigationDestination(isPresented: $viewModel.shouldNavigateToUserDetailsView, destination: {UserDetailsInputView(isOAuthUser: false)})
        .onAppear {
            startTimer()
            focusedIndex = 0
        }
        .onDisappear {
            timer?.invalidate()
        }
        .navigationBarHidden(true)
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var mainContent: some View {
        VStack(spacing: 32) {
            titleSection
            formSection
            resendSection
            errorSection
        }
        .padding(.horizontal, 40)
    }
    
    private var titleSection: some View {
        VStack(spacing: 16) {
            Text("Verify Your Email")
                .font(heading1)
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            Text("We've sent a 6-digit code to " + (viewModel.email ?? "your email"))
                .font(.onestRegular(size: 16))
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            verificationCodeInput
            verifyButton
        }
        .padding(.horizontal, 40)
    }
    
    private var verificationCodeInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verification Code")
                .font(.onestRegular(size: 16))
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { idx in
                    codeInputField(at: idx)
                }
            }
        }
    }
    
    private func codeInputField(at index: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(inputBackgroundColor)
                .frame(width: 48, height: 56)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.errorMessage != nil ? Color.red : Color.clear, lineWidth: 2)
                )
            TextField("", text: createBinding(for: index))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.onestRegular(size: 24))
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                .frame(width: 48, height: 56)
                .focused($focusedIndex, equals: index)
                .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
                    handlePaste()
                }
        }
        .onTapGesture {
            focusedIndex = index
        }
    }
    
    private func createBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { code[index] },
            set: { newValue in
                let previousValue = code[index]
                
                // Detect backspace: if previous value was not empty and new value is empty
                if !previousValue.isEmpty && newValue.isEmpty {
                    handleBackspace(at: index)
                } else {
                    handleTextChange(at: index, newValue: newValue)
                }
            }
        )
    }
    
    private var verifyButton: some View {
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
    
    private var resendSection: some View {
        HStack(spacing: 4) {
            Text("Didn't get it?")
                .font(.onestRegular(size: 16))
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            Button(action: {
                resendCode()
            }) {
                Text("Resend code")
                    .underline()
                    .font(.onestRegular(size: 16))
                    .foregroundColor(isResendEnabled ? figmaIndigo : universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
            }
            .disabled(!isResendEnabled)
            Text("in \(String(format: "%02d", secondsRemaining))")
                .font(.onestRegular(size: 16))
                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
                .opacity(isResendEnabled ? 0 : 1)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            Text("Invalid code. Try again.")
                .font(Font.custom("Onest", size: 14).weight(.medium))
                .foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
                .padding(.top, 8)
        }
    }
    
    private func handleTextChange(at index: Int, newValue: String) {
        // Handle pasting of multiple digits
        if newValue.count > 1 {
            let digits = newValue.filter { $0.isNumber }
            let digitArray = Array(digits)
            
            // Fill the boxes starting from the current index
            for i in 0..<min(digitArray.count, 6 - index) {
                if index + i < 6 {
                    code[index + i] = String(digitArray[i])
                }
            }
            
            // Move focus to the next empty box or the last box
            let nextIndex = min(index + digitArray.count, 5)
            focusedIndex = nextIndex
        } else {
            // Handle single character input
            if newValue.count <= 1 && (newValue.isEmpty || newValue.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil) {
                code[index] = newValue
                if !newValue.isEmpty && index < 5 {
                    focusedIndex = index + 1
                }
            }
        }
    }
    
    private func handleBackspace(at index: Int) {
        if code[index].isEmpty && index > 0 {
            // If current box is empty, move to previous box and clear it
            code[index - 1] = ""
            focusedIndex = index - 1
        } else {
            // If current box has content, just clear it
            code[index] = ""
        }
    }
    
    private func handlePaste() {
        // Get clipboard content
        guard let pasteboardString = UIPasteboard.general.string else { return }
        
        // Filter to only digits and take first 6
        let digits = pasteboardString.filter { $0.isNumber }
        let digitArray = Array(digits.prefix(6))
        
        // Only handle if we have digits
        if !digitArray.isEmpty {
            // Clear all boxes first
            code = Array(repeating: "", count: 6)
            
            // Fill boxes with pasted digits
            for (i, digit) in digitArray.enumerated() {
                if i < 6 {
                    code[i] = String(digit)
                }
            }
            
            // Move focus to the next empty box or the last filled box
            let nextIndex = min(digitArray.count, 5)
            focusedIndex = nextIndex
        }
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

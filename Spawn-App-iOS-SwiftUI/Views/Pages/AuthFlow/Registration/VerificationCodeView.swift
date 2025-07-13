import SwiftUI
import UIKit

struct BackspaceDetectingTextField: UIViewRepresentable {
    @Binding var text: String
    let onBackspace: () -> Void
    var keyboardType: UIKeyboardType = .numberPad
    var textAlignment: NSTextAlignment = .center
    var font: UIFont = UIFont.systemFont(ofSize: 24)
    var textColor: UIColor = .label
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textAlignment = textAlignment
        textField.font = font
        textField.textColor = textColor
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: BackspaceDetectingTextField
        
        init(_ parent: BackspaceDetectingTextField) {
            self.parent = parent
        }
        
        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            
            // Detect backspace on empty field
            if string.isEmpty && currentText.isEmpty {
                parent.onBackspace()
                return false
            }
            
            // Handle backspace on non-empty field
            if string.isEmpty && !currentText.isEmpty {
                return true
            }
            
            // Only allow single digits
			if string.count > 1 || (
				string.count == 1 && (
					(
						string
							.rangeOfCharacter(
								from: CharacterSet.decimalDigits.inverted
							)?.isEmpty
					) == nil
				) == false
			) {
                return false
            }
            
            // Only allow single character
            if currentText.count >= 1 && !string.isEmpty {
                return false
            }
            
            return true
        }
    }
}

struct VerificationCodeView: View {
    @ObservedObject var viewModel: UserAuthViewModel
    @State private var code: [String] = Array(repeating: "", count: 6)
    @State private var previousCode: [String] = Array(repeating: "", count: 6)
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
            previousCode = code
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
            BackspaceDetectingTextField(
                text: createBinding(for: index),
                onBackspace: {
                    handleBackspaceOnEmpty(at: index)
                },
                keyboardType: .numberPad,
                textAlignment: .center,
                font: UIFont(name: "Onest-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24),
                textColor: UIColor(universalAccentColor(from: themeService, environment: colorScheme))
            )
            .frame(width: 48, height: 56)
            .focused($focusedIndex, equals: index)
            .onChange(of: code[index]) { newValue in
                handleTextFieldChange(at: index, oldValue: previousCode[index], newValue: newValue)
                previousCode[index] = newValue
            }
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
                // The custom text field handles validation, so just update the value
                code[index] = newValue
            }
        )
    }
    
    private func handleTextFieldChange(at index: Int, oldValue: String, newValue: String) {
        // Handle forward navigation when a character is entered
        if oldValue.isEmpty && !newValue.isEmpty {
            // New character entered, move to next field
            if index < 5 {
                focusedIndex = index + 1
            }
        } else if !oldValue.isEmpty && newValue.isEmpty {
            // Backspace pressed on field with content - just clear it and stay
            // The custom text field already handles this
            return
        }
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
    

    
    private func handleBackspaceOnEmpty(at index: Int) {
        // This is called when backspace is pressed on an empty field
        if index > 0 {
            // Move to previous field and clear it
            code[index - 1] = ""
            previousCode[index - 1] = ""
            focusedIndex = index - 1
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
            previousCode = Array(repeating: "", count: 6)
            
            // Fill boxes with pasted digits
            for (i, digit) in digitArray.enumerated() {
                if i < 6 {
                    code[i] = String(digit)
                    previousCode[i] = String(digit)
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

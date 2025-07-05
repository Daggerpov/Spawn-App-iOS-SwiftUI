//
//  RegisterInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/2/25.
//

import SwiftUI

struct RegisterInputView: View {
    var body: some View {
        CoreInputView(heading: "Create Your Account", subtitle: "Choose how you'd like to set up your account.", label1: "Phone Number", label2: "Email", inputText1: "+1 123 456 7890", inputText2: "yourname@email.com", labelSubtitle: "We'll send you a 6-digit code to verify your phone number.", continueAction: {})
    }
}

#Preview {
    RegisterInputView()
}

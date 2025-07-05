//
//  LoginInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct LoginInputView: View {
    
    var body: some View {
        CoreInputView(heading: "Welcome Back", subtitle: "Your plans are waiting - time to spawn.", label1: "Email / Phone Number / Username", label2: "Password", inputText1: "Enter your email / phone / username", inputText2: "Enter your password", continueAction: {})
    }
}


struct WelcomeBackView_Previews: PreviewProvider {
    static var previews: some View {
        LoginInputView()
    }
}

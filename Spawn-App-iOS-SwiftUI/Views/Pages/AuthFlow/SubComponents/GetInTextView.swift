//
//  GetInTextView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct GetInTextView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Let's Get You In")
                .font(heading1)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text("Join your friends or start a hang. It's all happening here.")
                .font(body1)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }
}

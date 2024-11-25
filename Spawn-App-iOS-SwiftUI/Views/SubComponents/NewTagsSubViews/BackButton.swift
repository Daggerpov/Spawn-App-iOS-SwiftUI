//
//  BackButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct BackButton: View {
    var body: some View {
        Image(systemName: "arrow.left")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.black)
            .overlay(
                NavigationLink(destination: {
                    FeedView()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
            )
    }
}

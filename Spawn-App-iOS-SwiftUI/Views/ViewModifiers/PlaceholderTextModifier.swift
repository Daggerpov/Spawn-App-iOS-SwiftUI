//
//  PlaceholderTextModifier.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

// TODO: this modifier currently doesn't achieve
// my desired result -> look into fixing it
// For now, it's low-priority, since the search bar looks fine.
// But, ideally, the placeholder text would be the same
// color as the text upon typing

struct PlaceholderTextModifier: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                UITextField.appearance().attributedPlaceholder = NSAttributedString(
                    string: "Search",
                    attributes: [.foregroundColor: UIColor(color)]
                )
            }
    }
}

extension View {
    func placeholderColor(_ color: Color) -> some View {
        self.modifier(PlaceholderTextModifier(color: color))
    }
}

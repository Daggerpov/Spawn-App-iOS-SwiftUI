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
	var text: String

	func body(content: Content) -> some View {
		content
			.onAppear {
				UITextField.appearance().attributedPlaceholder =
					NSAttributedString(
						string: text,
						attributes: [.foregroundColor: UIColor(color)]
					)
			}
	}
}

extension View {
	func placeholderColor(color: Color, text: String) -> some View {
		self.modifier(PlaceholderTextModifier(color: color, text: text))
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @State var text = ""
	
	VStack(spacing: 20) {
		TextField("", text: $text)
			.placeholderColor(color: .blue, text: "Enter your text here")
			.padding()
			.border(Color.gray)
		
		TextField("", text: $text)
			.placeholderColor(color: .red, text: "Red placeholder text")
			.padding()
			.border(Color.gray)
	}
	.padding()
}

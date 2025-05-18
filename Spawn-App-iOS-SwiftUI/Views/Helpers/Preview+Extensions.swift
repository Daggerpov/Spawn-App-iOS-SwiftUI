//
//  Preview+Extensions.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-24.
//

import SwiftUI

/// Macro to easily set up previews with authentication
@_functionBuilder
struct PreviewableBuilder {
    static func buildBlock<V: View>(_ view: V) -> some View {
        view.withPreviewAuth()
            .environmentObject(AppCache.shared)
    }
}

/// Apply this macro to wrap your preview content with authentication
@available(iOS 17.0, *)
@resultBuilder
struct Previewable {
    static func buildBlock<V: View>(_ view: V) -> some View {
        view.withPreviewAuth()
            .environmentObject(AppCache.shared)
    }
} 
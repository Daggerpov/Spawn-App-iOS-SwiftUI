//
//  TagsScrollView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct TagsScrollView: View {
    let tags: [FilterTag]
    @Binding private var activeTag: FilterTag?
	@Namespace private var animation: Namespace.ID
    
    init(activeTag: Binding<FilterTag?>) {
        tags = [
            FilterTag(displayName: "Location", options: ["<1km", "<5km", ">5km"]),
            FilterTag(displayName: "Time", options: ["Ongoing", "In 6 hours", "Later Today"]),
            FilterTag(displayName: "Category", options: ["Sports", "Food & Drink", "Learning", "Social"])
        ]
        self._activeTag = activeTag
	}

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 12) {
				ForEach(tags, id: \.self) { tag in
                    TagButtonView(
                        tag: tag, activeTag: $activeTag, animation: animation
                    )
                    .onAppear {
                    }
				}
			}
			.padding(.top, 10)
			.padding(.horizontal, 16)
		}
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    @Previewable @State var activeTag: FilterTag? = nil
    TagsScrollView(activeTag: $activeTag).environmentObject(appCache)
}

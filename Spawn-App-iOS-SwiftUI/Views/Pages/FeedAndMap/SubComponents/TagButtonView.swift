//
//  TagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct TagButtonView: View {
    let tag: FilterTag
	@Binding var activeTag: FilterTag?  // Make activeTag optional
	var animation: Namespace.ID
    @State var showOptions: Bool = false
    @State var selectedOption: String?

	var body: some View {
        HStack {
            if showOptions {
                Button(action: {
                    withAnimation(.easeInOut) {
                        activeTag = nil
                        showOptions = false
                        selectedOption = nil
                    }
                }) {
                    Text("X")
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background {
                            Capsule()
                                .fill(universalPassiveColor)
                        }
                        .font(.onestRegular(size: 14))
                        .foregroundColor(
                            universalAccentColor
                        )
                }
            }
            if activeTag == nil || activeTag == tag {
                Button(action: {
                    withAnimation(.easeIn) {
                        activeTag = activeTag == nil ? tag : nil
                        showOptions = !showOptions
                        selectedOption = nil
                    }
                }) {
                    Text(tag.displayName)
                        .font(.onestRegular(size: 14))
                        .foregroundColor(
                            activeTag == tag ? universalPassiveColor : universalAccentColor
                        )
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background {
                            Capsule()
                                .fill(activeTag == tag ? universalAccentColor : universalPassiveColor)
                                .matchedGeometryEffect(
                                    id: "ACTIVETAG_\(tag.displayName)", in: animation)
                        }
                }
                .buttonStyle(.plain)
            }
            
            if showOptions {
                ForEach(tag.options, id: \.self) { option in
                    if selectedOption != nil {
                        if selectedOption == option {
                            TagOptionView(option: option, tag: tag, activeTag: $activeTag, selectedOption: $selectedOption)
                        }
                    } else {
                        TagOptionView(option: option, tag: tag, activeTag: $activeTag, selectedOption: $selectedOption)
                    }
                }
            }
        }
	}
}

struct TagOptionView: View {
    let option: String
    let tag: FilterTag
    @Binding var activeTag: FilterTag?
    @Binding var selectedOption: String?
    
    var body: some View {
        Button(action: {
            withAnimation(.easeIn) {
                activeTag = tag
                selectedOption = selectedOption == nil ? option : nil
            }
        }) {
            Text(option)
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background {
                    Capsule()
                        .fill(selectedOption == option ? universalAccentColor : universalPassiveColor)
                }
                .font(.onestRegular(size: 14))
                .foregroundColor(
                    selectedOption == option ? universalPassiveColor : universalAccentColor
                )
            }
        .buttonStyle(.plain)
    }
}

struct FilterTag: Equatable, Hashable {
    let displayName: String
    let options: [String]
}

@available(iOS 17, *)
#Preview {
    TagButtonPreview()
}

struct TagButtonPreview: View {
    @StateObject private var appCache = AppCache.shared
    @Namespace private var animation
    @State private var selectedTag: FilterTag? = nil

    var body: some View {
        let tag = FilterTag(
            displayName: "Location",
            options: ["<1km", "<5km", ">5km"]
        )

        TagButtonView(tag: tag, activeTag: $selectedTag, animation: animation)
            .environmentObject(appCache)
    }
}

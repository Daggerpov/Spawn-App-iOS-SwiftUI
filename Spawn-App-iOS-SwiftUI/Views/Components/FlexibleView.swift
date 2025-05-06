import SwiftUI

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: WidthPreferenceKey.self,
                    value: geometry.size.width
                )
            }
            .frame(height: 0)
            
            FlexibleViewContent(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                content: content
            )
        }
        .onPreferenceChange(WidthPreferenceKey.self) { width in
            availableWidth = width
        }
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct FlexibleViewContent<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var elementsSize: [Data.Element: CGSize] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        elementsSize[element] = geometry.size
                                    }
                                }
                            )
                    }
                }
            }
        }
    }
    
    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth
        
        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]
            
            if remainingWidth - (elementSize.width + spacing) >= 0 {
                rows[currentRow].append(element)
                remainingWidth -= elementSize.width + spacing
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth - elementSize.width
            }
        }
        
        return rows
    }
}

// Preview
struct FlexibleView_Previews: PreviewProvider {
    static var previews: some View {
        FlexibleView(data: ["Swift", "SwiftUI", "UIKit", "Objective-C", "Xcode", "iOS", "macOS"], spacing: 8) { item in
            Text(item)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
    }
} 
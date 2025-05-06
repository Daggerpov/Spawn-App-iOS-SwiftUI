import SwiftUI

struct CustomFlowLayout<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Hashable, Content: View {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    init(data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        VStack {
            let dataArray = Array(data)
            if !dataArray.isEmpty {
                TagLayoutView(
                    data: dataArray,
                    spacing: spacing,
                    content: content
                )
            }
        }
    }
}

// Simpler tag-based layout with better Swift type safety
struct TagLayoutView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var totalHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    TagView(index: index, maxWidth: geometry.size.width, spacing: spacing, totalHeight: $totalHeight) {
                        content(item)
                    }
                }
            }
        }
        .frame(height: totalHeight)
    }
}

struct TagView<Content: View>: View {
    let index: Int
    let maxWidth: CGFloat
    let spacing: CGFloat
    @Binding var totalHeight: CGFloat
    let content: () -> Content
    
    @State private var tagSize: CGSize = .zero
    @State private var tagPosition: CGPoint = .zero
    
    var body: some View {
        content()
            .fixedSize()
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: TagPreferenceKey.self, value: geometry.size)
                        .onPreferenceChange(TagPreferenceKey.self) { size in
                            if self.tagSize != size {
                                DispatchQueue.main.async {
                                    self.tagSize = size
                                    if index == 0 {
                                        self.tagPosition = CGPoint(x: 0, y: 0)
                                    }
                                    DispatchQueue.main.async {
                                        self.updateLayout()
                                    }
                                }
                            }
                        }
                }
            )
            .position(x: tagPosition.x + tagSize.width/2, y: tagPosition.y + tagSize.height/2)
    }
    
    private func updateLayout() {
        guard index > 0 else { return }
        
        // Get notification from previous tag view
        let previousTagPosition = NotificationCenter.default.publisher(for: Notification.Name("Tag\(index-1)Position"))
            .compactMap { notification -> CGPoint? in
                return notification.userInfo?["position"] as? CGPoint
            }
            .sink { point in
                // Calculate our position based on previous tag's position
                let previousTagFrame = CGRect(
                    x: point.x,
                    y: point.y,
                    width: notification.userInfo?["width"] as? CGFloat ?? 0,
                    height: notification.userInfo?["height"] as? CGFloat ?? 0
                )
                
                let rightEdge = previousTagFrame.maxX + spacing
                
                // Check if this tag fits on the same line
                if rightEdge + tagSize.width <= maxWidth {
                    // Same line
                    tagPosition = CGPoint(x: rightEdge, y: previousTagFrame.minY)
                } else {
                    // New line
                    tagPosition = CGPoint(x: 0, y: previousTagFrame.maxY + spacing)
                }
                
                // Update total height if necessary
                let newHeight = tagPosition.y + tagSize.height
                if newHeight > totalHeight {
                    totalHeight = newHeight
                }
                
                // Notify next tag
                NotificationCenter.default.post(
                    name: Notification.Name("Tag\(index)Position"),
                    object: nil,
                    userInfo: [
                        "position": tagPosition,
                        "width": tagSize.width,
                        "height": tagSize.height
                    ]
                )
            }
    }
}

struct TagPreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Replace with a much simpler solution that works reliably
extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Preview
struct CustomFlowLayout_Previews: PreviewProvider {
    static var previews: some View {
        CustomFlowLayout(data: ["Swimming", "Hiking", "Photography", "Basketball", "Cooking", "Reading", "Travel"], spacing: 10) { item in
            Text(item)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .foregroundColor(Color.blue)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .frame(height: 200)
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
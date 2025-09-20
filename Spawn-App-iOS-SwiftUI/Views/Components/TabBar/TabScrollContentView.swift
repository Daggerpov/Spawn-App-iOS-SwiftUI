import SwiftUI

struct TabScrollContentView: View {
    let tab: Tabs

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach((1 ... 3).reversed(), id: \.self) { _ in
                        if #available(iOS 17.0, *) {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(tab.item.color.opacity(0.5))
                                .frame(height: 180)
                                .scrollTransition { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1 : 0.8)
                                        .blur(radius: phase.isIdentity ? 0 : 10)
                                }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(tab.item.title)
        }
    }
}

#Preview {
    TabScrollContentView(tab: .home)
}

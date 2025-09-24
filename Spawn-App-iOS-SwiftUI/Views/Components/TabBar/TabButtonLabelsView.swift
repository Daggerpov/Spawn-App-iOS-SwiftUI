import SwiftUI

let BTTN_HEIGHT: CGFloat = 64
let CORNER_RADIUS: CGFloat = 100
let ICON_SIZE: CGFloat = 36

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
            configuration.title
        }
    }
}

struct ActiveTabLabel: View {
    let tabItem: TabItem
    @Binding var isAnimating: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CORNER_RADIUS)
                .fill(.white)
                .shadow(color: Color(hex: colorsTabIconInactive).opacity(0.05), radius: 3, x: 0, y: 5)
                .frame(width: 80, height: BTTN_HEIGHT)
            VStack(spacing: 1) {
                Image(
                    uiImage: resizeImage(
                        UIImage(named: tabItem.activeIcon)!,
                        targetSize: CGSize(width: ICON_SIZE, height: ICON_SIZE)
                )!)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .onAppear {
                    isAnimating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAnimating = false
                    }
                }
                .animation(.bouncy(duration: 0.2, extraBounce: 0.1), value: isAnimating)
                
                Text(tabItem.title)
                .font(.onestRegular(size: 12))
                .fontWeight(.semibold)
            }
            
        }
    }
}

struct InActiveTabLabel: View {
    let tabItem: TabItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CORNER_RADIUS)
                .fill(.clear)
                .frame(width: 80, height: BTTN_HEIGHT)
            if #available(iOS 17.0, *) {
                VStack(spacing: 1) {
                    Image(
                        uiImage: resizeImage(
                        UIImage(named: tabItem.inactiveIcon)!,
                        targetSize: CGSize(width: ICON_SIZE, height: ICON_SIZE)
                    )!)
                    Text(tabItem.title)
                        .font(.onestRegular(size: 12))
                        .fontWeight(.medium)
                }
                .symbolEffectsRemoved()
            } else {
                // Fallback for iOS < 17 (without symbol effects)
                VStack(spacing: 1) {
                    Image(
                        uiImage: resizeImage(
                        UIImage(named: tabItem.inactiveIcon)!,
                        targetSize: CGSize(width: ICON_SIZE, height: ICON_SIZE)
                    )!)
                    Text(tabItem.title)
                        .font(.onestRegular(size: 12))
                        .fontWeight(.medium)
                }
            }
        }
    }
}

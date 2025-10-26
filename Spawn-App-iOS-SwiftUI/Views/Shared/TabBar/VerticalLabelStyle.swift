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


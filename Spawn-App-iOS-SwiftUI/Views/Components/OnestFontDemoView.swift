import SwiftUI

struct OnestFontDemoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Onest Regular")
                .font(.onestRegular(size: 16))
            
            Text("Onest Medium")
                .font(.onestMedium(size: 16))
            
            Text("Onest Semi Bold")
                .font(.onestSemiBold(size: 16))
            
            Text("Onest Bold")
                .font(.onestBold(size: 16))
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Button")
                        .font(.onestSemiBold(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(figmaBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Text("Caption")
                    .onestCaption()
                    .foregroundColor(.gray)
                
                Text("Semi")
                    .onestSemibold(size: 14)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

// A convenient way to include the demo in any view
extension View {
    func withOnestFontDemo(isVisible: Bool = true) -> some View {
        ZStack {
            self
            
            if isVisible {
                VStack {
                    Spacer()
                    OnestFontDemoView()
                }
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    OnestFontDemoView()
} 
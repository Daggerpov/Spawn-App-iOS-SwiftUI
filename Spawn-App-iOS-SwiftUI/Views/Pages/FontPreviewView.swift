import SwiftUI

struct FontPreviewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Onest Font Preview")
                    .font(.onestBold(size: 24))
                    .padding(.bottom, 20)
                
                Group {
                    sectionTitle("Regular")
                    
                    Text("Regular 10pt")
                        .font(.onestRegular(size: 10))
                    Text("Regular 12pt")
                        .font(.onestRegular(size: 12))
                    Text("Regular 14pt")
                        .font(.onestRegular(size: 14))
                    Text("Regular 16pt")
                        .font(.onestRegular(size: 16))
                    Text("Regular 18pt")
                        .font(.onestRegular(size: 18))
                    Text("Regular 20pt")
                        .font(.onestRegular(size: 20))
                }
                
                Group {
                    sectionTitle("Medium")
                    
                    Text("Medium 10pt")
                        .font(.onestMedium(size: 10))
                    Text("Medium 12pt")
                        .font(.onestMedium(size: 12))
                    Text("Medium 14pt")
                        .font(.onestMedium(size: 14))
                    Text("Medium 16pt")
                        .font(.onestMedium(size: 16))
                    Text("Medium 18pt")
                        .font(.onestMedium(size: 18))
                    Text("Medium 20pt")
                        .font(.onestMedium(size: 20))
                }
                
                Group {
                    sectionTitle("Bold")
                    
                    Text("Bold 10pt")
                        .font(.onestBold(size: 10))
                    Text("Bold 12pt")
                        .font(.onestBold(size: 12))
                    Text("Bold 14pt")
                        .font(.onestBold(size: 14))
                    Text("Bold 16pt")
                        .font(.onestBold(size: 16))
                    Text("Bold 18pt")
                        .font(.onestBold(size: 18))
                    Text("Bold 20pt")
                        .font(.onestBold(size: 20))
                }
                
                Group {
                    sectionTitle("Modifiers")
                    
                    Text("onestHeadline()")
                        .onestHeadline()
                    Text("onestSubheadline()")
                        .onestSubheadline()
                    Text("onestBody()")
                        .onestBody()
                    Text("onestCaption()")
                        .onestCaption()
                    Text("onestSmallText()")
                        .onestSmallText()
                }
            }
            .padding()
        }
        .background(Color.white)
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.onestBold(size: 18))
            .foregroundColor(figmaBlue)
            .padding(.top, 10)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    FontPreviewView().environmentObject(appCache)
} 
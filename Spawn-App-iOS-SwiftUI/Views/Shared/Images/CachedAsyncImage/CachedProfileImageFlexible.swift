import SwiftUI

/// A cached async image for profile pictures with flexible sizing
struct CachedProfileImageFlexible: View {
    let userId: UUID
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        CachedAsyncImage(
            userId: userId,
            url: url,
            content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(Circle())
            },
            placeholder: {
                Circle()
                    .fill(Color.gray)
                    .frame(width: width, height: height)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: width * 0.5, height: height * 0.5)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        )
    }
}


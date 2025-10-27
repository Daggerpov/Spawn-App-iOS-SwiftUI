import SwiftUI

struct NotificationBadgeView: View {
    var count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: count > 9 ? 22 : 18, height: count > 9 ? 22 : 18)
            
            if count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: count > 9 ? 10 : 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// Extension to add a badge to any view
extension View {
    func withNotificationBadge(count: Int, offset: CGPoint = CGPoint(x: 12, y: -10)) -> some View {
        ZStack(alignment: .topTrailing) {
            self
            
            if count > 0 {
                NotificationBadgeView(count: count)
                    .offset(x: offset.x, y: offset.y)
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @ObservedObject var appCache = AppCache.shared
    VStack(spacing: 20) {
        Image(systemName: "bell.fill")
            .font(.system(size: 24))
            .withNotificationBadge(count: 3)
        
        Image(systemName: "envelope.fill")
            .font(.system(size: 24))
            .withNotificationBadge(count: 12)
        
        Image(systemName: "person.fill")
            .font(.system(size: 24))
            .withNotificationBadge(count: 100)
    }
    .padding()
} 

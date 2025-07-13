import SwiftUI

struct FriendRequestSuccessDrawer: View {
    let friendUser: BaseUserDTO
    @Binding var isPresented: Bool
    let onAddToActivityType: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Drawer content
            VStack(spacing: 0) {
                Spacer()
                
                // Main drawer
                VStack(spacing: 16) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color(red: 0.82, green: 0.80, blue: 0.80))
                        .frame(width: 50, height: 4)
                        .padding(.top, 12)
                    
                    Spacer().frame(height: 24)
                    
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(Color(hex: "#30D996"))
                    
                    // Success message
                    Text("Success!")
                        .font(.onestSemiBold(size: 24))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    Text("You've added \(friendUser.name ?? friendUser.username) as a friend")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    
                    // Add to Activity Type button
                    Button(action: {
                        isPresented = false
                        onAddToActivityType()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Add to Activity Type")
                                .font(.onestSemiBold(size: 20))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(figmaBlue)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    
                    Spacer().frame(height: 32)
                }
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.52, green: 0.49, blue: 0.49), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 32)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isPresented = true
    
    FriendRequestSuccessDrawer(
        friendUser: BaseUserDTO.danielAgapov,
        isPresented: $isPresented,
        onAddToActivityType: {}
    )
} 
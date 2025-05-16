import SwiftUI

struct CreateEventButton: View {
    @Binding var showEventCreationDrawer: Bool
    var body: some View {
        Button(action: {
            showEventCreationDrawer = true
        }) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                Text("Create an Event")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 1.0, green: 0.51, blue: 0.73), Color(red: 0.98, green: 0.36, blue: 0.56)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(40)
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
        }
    }
}

import SwiftUI

struct ActivityCreationLocationView: View {
    @State private var searchText: String = ""
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Where at?", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(universalAccentColor)
                .padding()
            
            // Current Location
            Button(action: {
                // Handle current location selection
            }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(universalSecondaryColor)
                    Text("Current Location")
                        .foregroundColor(universalAccentColor)
                    Spacer()
                    Text("5934 University Blvd")
                        .foregroundColor(figmaBlack300)
                }
                .padding()
                .background(universalPassiveColor.opacity(0.3))
                .cornerRadius(12)
            }
            
            List {
                ForEach(["UBC Sauder School of Business", "AMS Student Nest", "Starbucks Coffee", "Thunderbird Park"], id: \.self) { location in
                    Button(action: {
                        // Handle location selection
                    }) {
                        HStack {
                            Text(location)
                                .foregroundColor(universalAccentColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(figmaBlack300)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Button(action: onNext) {
                Text("Next Step")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(universalSecondaryColor)
                    .cornerRadius(12)
            }
            .padding()
        }
        .background(universalBackgroundColor)
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityCreationLocationView(
        onNext: {
            print("Next step tapped")
        }
    )
    .environmentObject(appCache)
} 

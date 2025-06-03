import SwiftUI

struct ActivityCreationLocationView: View {
    @State private var searchText: String = ""
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Where at?", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Current Location
            Button(action: {
                // Handle current location selection
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Current Location")
                    Spacer()
                    Text("5934 University Blvd")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .foregroundColor(.primary)
            
            List {
                ForEach(["UBC Sauder School of Business", "AMS Student Nest", "Starbucks Coffee", "Thunderbird Park"], id: \.self) { location in
                    Button(action: {
                        // Handle location selection
                    }) {
                        HStack {
                            Text(location)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
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
    }
} 

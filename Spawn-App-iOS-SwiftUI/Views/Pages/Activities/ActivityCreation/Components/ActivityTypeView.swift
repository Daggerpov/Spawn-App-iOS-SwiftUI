import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedType: ActivityType?
    let onNext: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What are you up to?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(universalAccentColor)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        ActivityTypeCard(type: type, selectedType: $selectedType)
                    }
                }
                .padding()
            }
            
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
            .disabled(selectedType == nil)
            .opacity(selectedType == nil ? 0.6 : 1)
        }
        .background(universalBackgroundColor)
    }
}

struct ActivityTypeCard: View {
    let type: ActivityType
    @Binding var selectedType: ActivityType?
    
    var body: some View {
        Button(action: { selectedType = type }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type.icon)
                        .font(.title)
                    Spacer()
                    Text("\(type.peopleCount) people")
                        .font(.caption)
                        .foregroundColor(figmaBlack300)
                }
                
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedType == type ? universalSecondaryColor.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedType == type ? universalSecondaryColor : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var selectedType: ActivityType? = .foodAndDrink
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityTypeView(
        selectedType: $selectedType,
        onNext: {
            print("Next step tapped")
        }
    )
    .environmentObject(appCache)
} 
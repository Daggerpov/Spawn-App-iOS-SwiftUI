import SwiftUI

struct ActivityTypeManagementView: View {
    let activityType: ActivityType
    @Environment(\.dismiss) private var dismiss
    @State private var showingOptions = false
    @State private var showingManagePeople = false
    
    // For testing empty state - in real app this would come from a data source
    let forceEmptyState: Bool
    
    init(activityType: ActivityType, forceEmptyState: Bool = false) {
        self.activityType = activityType
        self.forceEmptyState = forceEmptyState
    }
    
    private var effectivePeopleCount: Int {
        return forceEmptyState ? 0 : activityType.peopleCount
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(universalAccentColor)
                    }
                    
                    Spacer()
                    
                    Text("Manage Type - \(activityType.rawValue)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    Button(action: { showingOptions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(universalAccentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(universalBackgroundColor)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Activity Type Card
                        activityTypeCard
                        
                        // People Section
                        peopleSection
                    }
                    .padding()
                }
                .background(universalBackgroundColor)
            }
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingManagePeople) {
            ManagePeopleView(activityType: activityType)
        }
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text("Options"),
                buttons: [
                    .default(Text("Manage People")) {
                        showingManagePeople = true
                    },
                    .destructive(Text("Delete Activity Type")) {
                        // Handle delete activity type action
                        // This would typically show a confirmation dialog
                        // and then delete the activity type from the data source
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var activityTypeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 120)
            
            VStack(spacing: 8) {
                Text(activityType.icon)
                    .font(.system(size: 48))
                
                Text(activityType.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(universalAccentColor)
            }
            
            // Edit button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        // Handle edit action
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(16)
        }
        .padding(.horizontal)
    }
    
    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if effectivePeopleCount == 0 {
                // Empty state
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)
                    
                    VStack(spacing: 16) {
                        Text("No people yet!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(universalAccentColor)
                        
                        Text("You haven't added placed friends under this tag yet. Tap below to get started!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Button(action: { showingManagePeople = true }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add friends")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(.green)
                        )
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // People exist - show the list
                HStack {
                    Text("People (\(effectivePeopleCount))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    Button(action: { showingManagePeople = true }) {
                        Text("Manage People")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // People List
                LazyVStack(spacing: 12) {
                    ForEach(0..<min(effectivePeopleCount, 10), id: \.self) { index in
                        PersonRowView(person: samplePeople[index % samplePeople.count])
                    }
                }
            }
        }
    }
}

struct PersonRowView: View {
    let person: SamplePerson
    @State private var showingPersonOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: person.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Name and Username
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(universalAccentColor)
                
                Text("@\(person.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Options Button
            Button(action: { showingPersonOptions = true }) {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .actionSheet(isPresented: $showingPersonOptions) {
            ActionSheet(
                title: Text(person.name),
                buttons: [
                    .default(Text("View Profile")) {
                        // Handle view profile
                    },
                    .default(Text("Send Message")) {
                        // Handle send message
                    },
                    .destructive(Text("Remove from Type")) {
                        // Handle remove from type
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct ManagePeopleView: View {
    let activityType: ActivityType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Manage People for \(activityType.rawValue)")
                    .font(.title2)
                    .padding()
                
                // Add your manage people implementation here
                
                Spacer()
            }
            .navigationTitle("Manage People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Sample data for demonstration
struct SamplePerson {
    let name: String
    let username: String
    let imageUrl: String
}

let samplePeople: [SamplePerson] = [
    SamplePerson(name: "First Last", username: "example_user", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "Jane Smith", username: "jane_smith", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "John Doe", username: "john_doe", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "Alice Johnson", username: "alice_j", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "Bob Wilson", username: "bob_wilson", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "Sarah Davis", username: "sarah_d", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "Mike Brown", username: "mike_brown", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "Emily Garcia", username: "emily_g", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "David Miller", username: "david_m", imageUrl: "https://via.placeholder.com/40"),
    SamplePerson(name: "Lisa Anderson", username: "lisa_a", imageUrl: "https://via.placeholder.com/40")
]

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityTypeManagementView(activityType: .chill, forceEmptyState: true)
        .environmentObject(appCache)
} 
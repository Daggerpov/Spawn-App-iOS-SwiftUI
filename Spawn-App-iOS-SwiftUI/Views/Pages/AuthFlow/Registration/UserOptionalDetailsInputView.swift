import SwiftUI

struct UserOptionalDetailsInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var isLoading: Bool = false
    @ObservedObject var userAuth = UserAuthViewModel.shared
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    
    fileprivate func ProfilePic() -> some View {
        Group {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
            } else if userAuth.isLoggedIn, let pfpUrl = userAuth.profilePicUrl {
                AsyncImage(url: URL(string: pfpUrl)) { image in
                    image
                        .ProfileImageModifier(imageType: .profilePage)
                } placeholder: {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 150, height: 150)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            } else if let defaultPfpUrl = userAuth.defaultPfpUrlString {
                AsyncImage(url: URL(string: defaultPfpUrl)) { image in
                    image
                        .ProfileImageModifier(imageType: .profilePage)
                } placeholder: {
                    Circle()
                        .fill(.gray)
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 150, height: 150)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
    }
    
    var body: some View {
       
        VStack(spacing: 0) {
            // Navigation Bar
//            HStack {
//                Button(action: {
//                    // Clear any error states when going back
//                    userAuth.clearAllErrors()
//                    dismiss()
//                }) {
//                    Image(systemName: "chevron.left")
//                        .font(.title2)
//                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
//                }
//                Spacer()
//            }
//            .padding(.horizontal, 20)
//            .padding(.top, 10)
            
            Spacer()
            
            // Main Content
            VStack(spacing: 32) {
                // Title and Subtitle
                VStack(spacing: 16) {
                    Text("Make It Yours")
                        .font(heading1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    Text("Add a name and photo so your friends can find you easily.")
                        .font(body1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                // Profile Photo Picker
                VStack {
                    ZStack {
                        ProfilePic()

                        Circle()
                            .fill(Color.black)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                            )
                            .offset(x: 55, y: 55)
                            .shadow(radius: 3)
                    }
                    .onTapGesture {
                        showImagePicker = true
                    }
                    .sheet(isPresented: $showImagePicker) {
                        SwiftUIImagePicker(selectedImage: $selectedImage)
                    }
                }
                
                // Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(Font.onestRegular(size: 16))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    TextField("What should your friends call you?", text: $name)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.name)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 40)
                
                // Error Message
                if let errorMessage = userAuth.errorMessage {
                    Text(errorMessage)
                        .font(.onestRegular(size: 15))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Continue Button
                Button(action: {
                    Task {
                        isLoading = true
                        guard let user = userAuth.spawnUser else { return }
                        await userAuth.updateOptionalDetails(
                            id: user.id.uuidString,
                            name: name,
                            profileImage: selectedImage
                        )
                        isLoading = false
                    }
                }) {
                    OnboardingButtonCoreView(isLoading ? "Updating..." : "Continue") {
                        isFormValid ? figmaIndigo : Color.gray.opacity(0.6)
                    }
                }
                .disabled(!isFormValid || isLoading)
            }
            
            Spacer()
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            // Clear any previous error state when this view appears
            userAuth.clearAllErrors()
            // Pre-populate the name field with the user's current name
            if let currentName = userAuth.spawnUser?.name, !currentName.isEmpty {
                name = currentName
            }
        }
    }
}

#Preview {
    UserOptionalDetailsInputView()
} 

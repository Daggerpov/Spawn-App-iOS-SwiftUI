# Preview Authentication System

This system allows SwiftUI previews to run with real Google authentication, enabling actual API calls to be made during development and preview instead of using mock data.

## How It Works

The `Previewable` property wrapper automatically handles authentication for preview contexts. When used in preview code, it:

1. Loads authentication credentials from either a JSON file or environment variables
2. Authenticates the UserAuthViewModel with these credentials
3. Makes the real API calls using the authenticated user

## Setting Up Your Credentials

There are two ways to provide credentials:

### 1. Using the Credentials Storage Button (Recommended)

1. Add the `StorePreviewCredentialsButton` to any view in your app while testing
2. Log in to the app with your Google account
3. Tap the "Save Auth for Previews" button to store your credentials
4. The credentials will be saved to a local JSON file that is gitignored

```swift
struct YourView: View {
    var body: some View {
        VStack {
            // Your normal view content
            
            // Add this to save credentials (can be removed after saving)
            StorePreviewCredentialsButton()
        }
    }
}
```

### 2. Using Environment Variables

You can also set environment variables in your Xcode scheme:

1. Edit your scheme (Product > Scheme > Edit Scheme)
2. Go to Run > Arguments > Environment Variables
3. Add:
   - `SPAWN_AUTH_EMAIL`: Your Google account email
   - `SPAWN_AUTH_USER_ID`: Your Google user ID

## Using in Previews

Simply add the `@Previewable` property wrapper to any state objects or state variables in your preview:

```swift
@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    @Previewable @State var someState = initialValue
    
    YourView()
        .environmentObject(appCache)
}
```

Alternatively, use the `withPreviewEnvironment()` modifier:

```swift
@available(iOS 17, *)
#Preview {
    YourView()
        .withPreviewEnvironment()
}
```

## Privacy and Security

- Credentials are stored locally and gitignored
- Never commit your preview_credentials.json file to git
- Each developer should set up their own credentials

## Troubleshooting

- If authentication fails, check your network connection
- Ensure your credentials are valid
- Look for authentication errors in the console
- Try restarting the preview 
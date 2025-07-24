//
//  WelcomeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animationCompleted = false
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var userAuth = UserAuthViewModel.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                if !animationCompleted {
                    // Initial Rive animation for new users
                    RiveAnimationView.logoAnimation(fileName: "spawn_logo_animation")
                        .frame(width: 300, height: 300)
                        .onAppear {
                            print("🎬 DEBUG: Starting logo animation in WelcomeView")
                            // Show content after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    animationCompleted = true
                                    print("🎬 DEBUG: Animation completed, showing Get Started button")
                                }
                            }
                        }
                } else {
					Spacer()
					Spacer()
					Spacer()
					Spacer()
					Spacer()
                    // Static logo after animation
                    Image("SpawnLogo")
                        .scaledToFit()
                        .transition(.opacity)
						.padding(.bottom, 12)
                }
                
                if animationCompleted {
                    Text("Spontaneity made easy.")
						.font(.onestRegular(size: 20))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .transition(.opacity)

                    // Skip onboarding for returning users
                    if userAuth.hasCompletedOnboarding {
                        OnboardingButtonView("Get Started", destination: SignInView())
                            .padding(.bottom, 12)
                            .transition(.opacity)
                            .onAppear {
                                print("🔘 DEBUG: Showing Get Started button (for returning users)")
                            }
                    } else {
						Spacer()
                        OnboardingButtonView("Get Started", destination: SpawnIntroView())
							.padding(.top, 12)
                            .transition(.opacity)
                            .onAppear {
                                print("🔘 DEBUG: Showing Get Started button (for new users)")
                            }
                    }
                }
                
                Spacer()
            }
            .background(universalBackgroundColor(from: themeService, environment: colorScheme))
            .ignoresSafeArea(.all)
            .onAppear {
                print("🔄 DEBUG: WelcomeView appeared - animationCompleted: \(animationCompleted), hasCompletedOnboarding: \(userAuth.hasCompletedOnboarding)")
            }
        }
        .navigationDestination(isPresented: .constant(userAuth.navigationState != .none)) {
            switch userAuth.navigationState {
            case .userDetailsInput(let isOAuthUser):
                UserDetailsInputView(isOAuthUser: isOAuthUser)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .onAppear {
                        userAuth.navigationState = .none
                    }
            case .userOptionalDetailsInput:
                UserOptionalDetailsInputView()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .onAppear {
                        userAuth.navigationState = .none
                    }
            case .contactImport:
                ContactImportView()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .onAppear {
                        userAuth.navigationState = .none
                    }
            case .userTermsOfService:
                UserToS()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .onAppear {
                        userAuth.navigationState = .none
                    }
            case .feedView:
                if let loggedInSpawnUser = userAuth.spawnUser {
                    ContentView(user: loggedInSpawnUser)
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                        .onAppear {
                            userAuth.navigationState = .none
                        }
                } else {
                    EmptyView()
                }
            case .accountNotFound:
                AccountNotFoundView()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    .onAppear {
                        userAuth.navigationState = .none
                    }
            case .onboardingContinuation:
                OnboardingContinuationView()
                    .onAppear {
                        userAuth.navigationState = .none
                    }
            default:
                EmptyView()
            }
        }
        
    }
}

#Preview {
    WelcomeView()
}

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
                    // Static logo after animation with debug border
                    Image("SpawnLogo")
                        .scaledToFit()
                        .transition(.opacity)
						.padding(.bottom, 12)
                        .border(Color.red, width: 2) // DEBUG: Add visible border
                        .onAppear {
                            print("🖼️ DEBUG: SpawnLogo image appeared")
                        }
                }
                
                if animationCompleted {
                    // DEBUG: Use hardcoded visible colors
                    Text("Spontaneity made easy.")
						.font(.onestRegular(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black) // DEBUG: Hardcoded colors
                        .transition(.opacity)
                        .border(Color.blue, width: 1) // DEBUG: Add visible border
                        .onAppear {
                            print("📝 DEBUG: 'Spontaneity made easy' text appeared")
                        }

                    // Skip onboarding for returning users
                    if userAuth.hasCompletedOnboarding {
                        // DEBUG: Replace OnboardingButtonView with simple NavigationLink
                        NavigationLink(destination: SignInView()) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                        .padding(.bottom, 12)
                        .transition(.opacity)
                        .border(Color.green, width: 2) // DEBUG: Add visible border
                        .onAppear {
                            print("🔘 DEBUG: Hardcoded Get Started button appeared (for returning users)")
                        }
                    } else {
						Spacer()
                        // DEBUG: Replace OnboardingButtonView with simple NavigationLink
                        NavigationLink(destination: SpawnIntroView()) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                        .padding(.top, 12)
                        .transition(.opacity)
                        .border(Color.orange, width: 2) // DEBUG: Add visible border
                        .onAppear {
                            print("🔘 DEBUG: Hardcoded Get Started button appeared (for new users)")
                        }
                    }
                }
                
                Spacer()
            }
            .background(colorScheme == .dark ? Color.black : Color.white) // DEBUG: Hardcoded background
            .ignoresSafeArea(.all)
            .onAppear {
                print("🔄 DEBUG: WelcomeView appeared - animationCompleted: \(animationCompleted), hasCompletedOnboarding: \(userAuth.hasCompletedOnboarding)")
                print("🎨 DEBUG: Current colorScheme: \(colorScheme)")
                print("🎨 DEBUG: ThemeService colorScheme: \(themeService.colorScheme)")
            }
            .navigationDestination(isPresented: $userAuth.shouldSkipAhead) {
                switch userAuth.skipDestination {
                case .userDetailsInput:
                    UserDetailsInputView()
                case .userOptionalDetailsInput:
                    UserOptionalDetailsInputView()
                case .contactImport:
                    ContactImportView()
                case .userToS:
                    UserToS()
                case .none:
                    EmptyView()
                }
            }
        }
        
    }
}

#Preview {
    WelcomeView()
}

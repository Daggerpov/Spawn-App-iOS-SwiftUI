////
////  OnboardingViewModel.swift
////  Spawn-App-iOS-SwiftUI
////
////  Created by Shane on 7/6/25.
////
//
//import Foundation
//
//class OnboardingViewModel: ObservableObject {
//  
//    @Published var errorMessage: Bool = false
//
//    
//    private init(apiService: IAPIService) {
//        // Attempt quick login
//        
//    }
//    
//    func register(email: String?, idToken: String?, provider: AuthProviderType?) async {
//        do {
//            if let url: URL = URL(string: APIService.baseURL + "auth/registration") {
//                let registration: RegistrationDTO = RegistrationDTO(email: email, idToken: idToken, provider: provider?.rawValue)
//                let response: BaseUserDTO? = try await self.apiService.sendData(registration, to: url, parameters: nil)
//                guard let user: BaseUserDTO = response else {
//                    print("Failed to register account")
//                    return
//                }
//                
//                await MainActor.run {
//                    self.shouldNavigateToPhoneNumberView = true
//                }
//            }
//            
//        } catch {
//            print("Error registering user")
//            self.shouldNavigateToPhoneNumberView = false
//        }
//    }
//}

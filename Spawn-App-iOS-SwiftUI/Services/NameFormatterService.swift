//
//  NameFormatterService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

class NameFormatterService {
    static let shared: NameFormatterService = NameFormatterService()
    
    private init() {}
    
    public func formatName(appUser: AppUser) -> String {
        if let firstName = appUser.firstName {
            if let lastName = appUser.lastName {
                return "\(firstName) \(lastName)"
            } else {
                return firstName
            }
        }
        if let lastName = appUser.lastName {
            return lastName
        }
        return ""
    }
}

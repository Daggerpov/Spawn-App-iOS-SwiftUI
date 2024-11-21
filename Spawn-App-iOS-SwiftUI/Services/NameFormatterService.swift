//
//  NameFormatterService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

class NameFormatterService {
    static let shared: NameFormatterService = NameFormatterService()
    
    private init() {}
    
    public func formatName(user: User) -> String {
        if let firstName = user.firstName {
            if let lastName = user.lastName {
                return "\(firstName) \(lastName)"
            } else {
                return firstName
            }
        }
        if let lastName = user.lastName {
            return lastName
        }
        return ""
    }
}

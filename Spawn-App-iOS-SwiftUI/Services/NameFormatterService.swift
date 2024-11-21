//
//  NameFormatterService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

class NameFormatterService {
    static let shared: NameFormatterService = NameFormatterService()
    
    private init() {}
    
    public func formatName(User: User) -> String {
        if let firstName = User.firstName {
            if let lastName = User.lastName {
                return "\(firstName) \(lastName)"
            } else {
                return firstName
            }
        }
        if let lastName = User.lastName {
            return lastName
        }
        return ""
    }
}

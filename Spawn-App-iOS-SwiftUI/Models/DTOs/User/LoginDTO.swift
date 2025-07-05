//
//  LoginDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/2/25.
//

struct LoginDTO: Codable, Hashable {
    static func == (lhs: LoginDTO, rhs: LoginDTO) -> Bool {
        return lhs.username == rhs.username
    }
    
    let username: String
    let password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

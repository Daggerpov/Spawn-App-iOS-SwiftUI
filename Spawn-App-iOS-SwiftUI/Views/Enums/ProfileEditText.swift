//
//  ProfileEditText.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

enum ProfileEditText {
    case edit, save
    func displayText() -> String {
        switch self {
            case .edit: return "Edit"
            case .save: return "Save"
        }
    }
}

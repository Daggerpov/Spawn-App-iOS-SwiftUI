//
//  KeychainService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-13.
//

import Foundation
import Security

class KeychainService {
	static let shared = KeychainService()
	private let service = "danielagapov.Spawn-App-iOS-SwiftUI"

	private init() {}

	func save(key: String, data: Data) -> Bool {
		let query =
			[
				kSecClass as String: kSecClassGenericPassword as String,
				kSecAttrService as String: service,
				kSecAttrAccount as String: key,
				kSecValueData as String: data,
				kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
			] as [String: Any]

		SecItemDelete(query as CFDictionary)  // Delete existing item if any
		let status = SecItemAdd(query as CFDictionary, nil)
		if status != errSecSuccess {
			print("❌ Keychain save error: \(status) for key \(key)")
			return false
		}
		return true
	}

	func load(key: String) -> Data? {
		let query =
			[
				kSecClass as String: kSecClassGenericPassword as String,
				kSecAttrService as String: service,
				kSecAttrAccount as String: key,
				kSecReturnData as String: kCFBooleanTrue!,
				kSecMatchLimit as String: kSecMatchLimitOne,
			] as [String: Any]

		var dataTypeRef: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

		if status == errSecSuccess {
			return dataTypeRef as? Data
		}
		if status != errSecItemNotFound {
			print("❌ Keychain load error: \(status) for key \(key)")
		}
		return nil
	}

	func delete(key: String) -> Bool {
		let query =
			[
				kSecClass as String: kSecClassGenericPassword as String,
				kSecAttrService as String: service,
				kSecAttrAccount as String: key,
			] as [String: Any]

		let status = SecItemDelete(query as CFDictionary)
		if status != errSecSuccess && status != errSecItemNotFound {
			print("❌ Keychain delete error: \(status) for key \(key)")
			return false
		}
		return true
	}

	// A more robust method that attempts multiple times before giving up
	func saveWithRetry(key: String, data: Data, retryCount: Int = 3) -> Bool {
		for attempt in 1...retryCount {
			if save(key: key, data: data) {
				return true
			}
			print("Retrying keychain save for \(key), attempt \(attempt)/\(retryCount)")
			// Short delay before retry
			Thread.sleep(forTimeInterval: 0.1)
		}
		return false
	}
}

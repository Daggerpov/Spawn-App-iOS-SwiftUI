//
//  AppLog.swift
//  Spawn-App-iOS-SwiftUI
//
//  Centralized logging with severity levels. Adjust `minimumLevel` to control console noise
//  (e.g. `.warning` for errors/warnings only, `.info` or `.debug` when investigating issues).
//

import Foundation

enum AppLog {
	enum Level: Int, Comparable {
		case debug = 0
		case info = 1
		case warning = 2
		case error = 3

		static func < (lhs: Level, rhs: Level) -> Bool {
			lhs.rawValue < rhs.rawValue
		}
	}

	/// Only messages at this level or higher are printed. Default is quiet (warnings and errors).
	nonisolated(unsafe) static var minimumLevel: Level = .warning

	static func log(_ level: Level, category: String? = nil, _ message: @autoclosure () -> String) {
		guard level >= minimumLevel else { return }
		let prefix = category.map { "[\($0)] " } ?? ""
		print("\(prefix)\(message())")
	}

	static func debug(_ message: @autoclosure () -> String, category: String? = nil) {
		log(.debug, category: category, message())
	}

	static func info(_ message: @autoclosure () -> String, category: String? = nil) {
		log(.info, category: category, message())
	}

	static func warning(_ message: @autoclosure () -> String, category: String? = nil) {
		log(.warning, category: category, message())
	}

	static func error(_ message: @autoclosure () -> String, category: String? = nil) {
		log(.error, category: category, message())
	}
}

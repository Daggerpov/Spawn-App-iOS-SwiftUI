//
//  ErrorFormattingService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-22.
//

import Foundation

/// Service responsible for converting raw technical error messages into user-friendly text
class ErrorFormattingService {
    static let shared = ErrorFormattingService()
    
    private init() {}
    
    /// Converts any error into a user-friendly message suitable for display
    /// - Parameter error: The error to format
    /// - Returns: A user-friendly error message
    func formatError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return formatAPIError(apiError)
        }
        
        return formatGenericError(error.localizedDescription)
    }
    
    /// Formats API-specific errors with appropriate user messages
    /// - Parameter apiError: The API error to format
    /// - Returns: A user-friendly error message
    func formatAPIError(_ apiError: APIError) -> String {
        switch apiError {
        case .failedHTTPRequest:
            return "We're having trouble connecting to our servers. Please try again."
        case .invalidStatusCode(let statusCode):
            return formatStatusCodeError(statusCode)
        case .failedJSONParsing:
            return "We're having trouble processing the server response. Please try again."
        case .invalidData:
            return "The information received from the server is invalid. Please try again."
        case .URLError:
            return "Unable to connect to the server. Please check your internet connection and try again."
        case .unknownError(let error):
            return formatGenericError(error.localizedDescription)
        case .failedTokenSaving:
            return "There was an issue with authentication. Please try signing in again."
        case .cancelled:
            return "Request was cancelled." // This typically shouldn't be shown to users
        }
    }
    
    /// Formats HTTP status code errors into user-friendly messages
    /// - Parameter statusCode: The HTTP status code
    /// - Returns: A user-friendly error message
    private func formatStatusCodeError(_ statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "Please check your information and try again."
        case 401:
            return "Authentication failed. Please sign in again."
        case 403:
            return "You don't have permission to perform this action."
        case 404:
            return "The requested information could not be found."
        case 409:
            return "This information is already in use. Please try different details."
        case 429:
            return "Too many attempts. Please wait a few minutes and try again."
        case 500...599:
            return "We're experiencing technical difficulties. Please try again in a few moments."
        default:
            return "We're having trouble processing your request. Please try again."
        }
    }
    
    /// Formats generic error messages into user-friendly alternatives
    /// - Parameter rawMessage: The raw error message
    /// - Returns: A user-friendly error message
    func formatGenericError(_ rawMessage: String) -> String {
        let lowercased = rawMessage.lowercased()
        
        // Network-related errors
        if lowercased.contains("network") || lowercased.contains("connection") || 
           lowercased.contains("timeout") || lowercased.contains("unreachable") {
            return "Unable to connect to the server. Please check your internet connection and try again."
        }
        
        // Server errors
        if lowercased.contains("server") || lowercased.contains("internal") || 
           lowercased.contains("500") || lowercased.contains("503") {
            return "We're experiencing technical difficulties. Please try again in a few moments."
        }
        
        // Authentication errors
        if lowercased.contains("unauthorized") || lowercased.contains("401") || 
           lowercased.contains("forbidden") || lowercased.contains("403") || 
           lowercased.contains("token") || lowercased.contains("auth") {
            return "Authentication failed. Please try signing in again."
        }
        
        // Validation errors
        if lowercased.contains("validation") || lowercased.contains("invalid") || 
           lowercased.contains("format") || lowercased.contains("required") {
            return "Please check your information and try again."
        }
        
        // Rate limiting
        if lowercased.contains("rate") || lowercased.contains("limit") || 
           lowercased.contains("429") || lowercased.contains("too many") {
            return "Too many attempts. Please wait a few minutes and try again."
        }
        
        // Conflict/duplicate errors
        if lowercased.contains("conflict") || lowercased.contains("duplicate") || 
           lowercased.contains("already exists") || lowercased.contains("409") {
            return "This information is already in use. Please try different details."
        }
        
        // Generic fallback - never show raw technical errors to users
        return "We're having trouble processing your request. Please try again."
    }
    
    /// Formats error messages specifically for onboarding flows with more context
    /// - Parameters:
    ///   - error: The error to format
    ///   - context: Additional context about where the error occurred (e.g., "account creation", "phone verification")
    /// - Returns: A contextual user-friendly error message
    func formatOnboardingError(_ error: Error, context: String) -> String {
        let baseMessage = formatError(error)
        
        // Add context-specific guidance for onboarding
        switch context.lowercased() {
        case "account creation", "registration":
            if baseMessage.contains("already in use") {
                return "\(baseMessage) If you already have an account, try signing in instead."
            }
        case "phone verification", "verification":
            return "We're having trouble verifying your phone number. Please check the number and try again."
        case "profile setup":
            return "We're having trouble saving your profile information. Please check your details and try again."
        default:
            break
        }
        
        return baseMessage
    }
}



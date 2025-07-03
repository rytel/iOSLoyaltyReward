//
// Copyright © 2022 Future Mind. All rights reserved.
//


import Foundation
import RewardsAPI

struct ErrorMessageFactory {
    static func message(for error: Error) -> String {
        if let httpError = error as? HttpError {
            switch httpError {
            case .badRequest:
                return "Bad request. Please try again."
            case .resourceNotFound:
                return "Resource not found."
            case .serverUnavailable:
                return "Server is unavailable. Please try again later."
            default:
                return "An unexpected error occurred: \(error.localizedDescription)"
            }
        } else {
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

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
                return "Błędne żądanie. Spróbuj ponownie."
            case .resourceNotFound:
                return "Nie znaleziono zasobu."
            case .serverUnavailable:
                return "Serwer jest niedostępny. Spróbuj później."
            default:
                return "Wystąpił nieoczekiwany błąd: \(error.localizedDescription)"
            }
        } else {
            return "Wystąpił nieoczekiwany błąd: \(error.localizedDescription)"
        }
    }
}

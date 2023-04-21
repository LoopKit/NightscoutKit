//
//  NightscoutError.swift
//  
//
//  Created by Pete Schwamb on 2/20/23.
//

import Foundation

public enum NightscoutError: LocalizedError {
    case httpError(status: Int, body: String)
    case missingTimezone
    case invalidResponse(reason: String)
    case unauthorized
    case missingConfiguration
    case invalidParameters
    case networkError(error: Error)

    init(response: HTTPURLResponse, data: Data?) {
        if let data, let body = String(data: data, encoding: String.Encoding.utf8) {
            self = .httpError(status: response.statusCode, body: body)
        } else {
            self = .httpError(status: response.statusCode, body: "Response body is binary.")
        }
    }

    public var errorDescription: String? {
        switch self {
        case .httpError(let status, let body):
            return String(format: LocalizedString("HTTP Error\nStatus Code: %1$@\nbody: %2$@", comment: "errorDescription format string for NightscoutError.httpError (1: http status code) (2: http body for error)"), String(describing: status), body)
        case .missingTimezone:
            return LocalizedString("Missing Timezone", comment: "errorDescription for NightscoutError.missingTimezone")
        case .invalidResponse(let reason):
            return String(format: LocalizedString("Invalid Response: %$1@", comment: "errorDescription format string for NightscoutError.invalidResponse (1: reason)"), reason)
        case .unauthorized:
            return LocalizedString("Unauthorized", comment: "errorDescription for NightscoutError.unauthorized")
        case .missingConfiguration:
            return LocalizedString("Missing Nightscout Credentials", comment: "errorDescription for NightscoutError.missingConfiguration")
        case .invalidParameters:
            return LocalizedString("Invalid parameters", comment: "errorDescription for NightscoutError.invalidParameters")
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

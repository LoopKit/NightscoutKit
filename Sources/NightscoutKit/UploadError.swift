//
//  UploadError.swift
//  
//
//  Created by Pete Schwamb on 2/20/23.
//

import Foundation

public enum UploadError: LocalizedError {
    case httpError(status: Int, body: String)
    case missingTimezone
    case invalidResponse(reason: String)
    case unauthorized
    case missingConfiguration
    case invalidParameters
    case unexpectedResult(description: String)

    public var errorDescription: String? {
        switch self {
        case .httpError(let status, let body):
            return String(["HTTP Error", "Status Code: \(status)" ,"body: body: \(body)"].joined( separator: "\n"))
        case .missingTimezone:
            return "Missing Timezone"
        case .invalidResponse(let reason):
            return "Invalid Response: \(reason)"
        case .unauthorized:
            return "Unauthorized"
        case .missingConfiguration:
            return "Missing Nightscout Credentials"
        case .invalidParameters:
            return "Invalid parameters"
        case .unexpectedResult(let description):
            return "Unexpected Result: \(description)"
        }
    }
}

//
//  BolusCalculation.swift
//  NightscoutKit
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import Foundation

/// What the bolus calculator used and recommended for a manual bolus.
public struct BolusCalculation {
    typealias RawValue = [String: Any]

    public let requested: Double
    public let recommended: Double?
    public let recommendationDate: Date?
    public let carbs: Double?  // grams
    public let carbsDate: Date?
    public let carbSyncIdentifier: String?
    public let glucose: Double?  // mg/dL
    public let glucoseDate: Date?

    public init(requested: Double, recommended: Double? = nil, recommendationDate: Date? = nil, carbs: Double? = nil, carbsDate: Date? = nil, carbSyncIdentifier: String? = nil, glucose: Double? = nil, glucoseDate: Date? = nil) {
        self.requested = requested
        self.recommended = recommended
        self.recommendationDate = recommendationDate
        self.carbs = carbs
        self.carbsDate = carbsDate
        self.carbSyncIdentifier = carbSyncIdentifier
        self.glucose = glucose
        self.glucoseDate = glucoseDate
    }

    public var dictionaryRepresentation: [String: Any] {
        var rval = [String: Any]()

        rval["requested"] = requested
        rval["recommended"] = recommended
        rval["recommendationDate"] = recommendationDate.map { TimeFormat.timestampStrFromDate($0) }
        rval["carbs"] = carbs
        rval["carbsDate"] = carbsDate.map { TimeFormat.timestampStrFromDate($0) }
        rval["carbSyncIdentifier"] = carbSyncIdentifier
        rval["glucose"] = glucose
        rval["glucoseDate"] = glucoseDate.map { TimeFormat.timestampStrFromDate($0) }

        return rval
    }

    init?(rawValue: RawValue) {
        guard let requested = rawValue["requested"] as? Double else {
            return nil
        }

        self.requested = requested
        self.recommended = rawValue["recommended"] as? Double
        self.recommendationDate = (rawValue["recommendationDate"] as? String).flatMap { TimeFormat.dateFromTimestamp($0) }
        self.carbs = rawValue["carbs"] as? Double
        self.carbsDate = (rawValue["carbsDate"] as? String).flatMap { TimeFormat.dateFromTimestamp($0) }
        self.carbSyncIdentifier = rawValue["carbSyncIdentifier"] as? String
        self.glucose = rawValue["glucose"] as? Double
        self.glucoseDate = (rawValue["glucoseDate"] as? String).flatMap { TimeFormat.dateFromTimestamp($0) }
    }
}

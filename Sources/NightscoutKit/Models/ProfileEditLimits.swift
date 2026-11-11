//
//  ProfileEditLimits.swift
//  NightscoutKit
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import Foundation

/// The bounds a remote editor of a profile set's profiles must keep to, as set by the uploader.
/// Glucose limits and steps are in `units`.
public struct ProfileEditLimits: Equatable {
    typealias RawValue = [String: Any]

    public struct ValueLimits: Equatable {
        typealias RawValue = [String: Any]

        public let min: Double
        public let max: Double
        public let step: Double
        /// Bounds outside which the uploader warns, when it has any.
        public let recommendedMin: Double?
        public let recommendedMax: Double?

        public init(min: Double, max: Double, step: Double, recommendedMin: Double? = nil, recommendedMax: Double? = nil) {
            self.min = min
            self.max = max
            self.step = step
            self.recommendedMin = recommendedMin
            self.recommendedMax = recommendedMax
        }

        public var dictionaryRepresentation: [String: Any] {
            var rval: [String: Any] = [
                "min": min,
                "max": max,
                "step": step,
            ]
            rval["recommendedMin"] = recommendedMin
            rval["recommendedMax"] = recommendedMax
            return rval
        }

        init?(rawValue: RawValue) {
            guard
                let min = rawValue["min"] as? Double,
                let max = rawValue["max"] as? Double,
                let step = rawValue["step"] as? Double
            else {
                return nil
            }

            self.min = min
            self.max = max
            self.step = step
            self.recommendedMin = rawValue["recommendedMin"] as? Double
            self.recommendedMax = rawValue["recommendedMax"] as? Double
        }
    }

    public let units: String
    public let maxBasal: Double
    /// The basal rates the pump supports, up to `maxBasal`.
    public let basalRates: [Double]
    /// The lowest basal rate allowed, when it is above the lowest supported rate.
    public let basalMinimum: Double?
    /// The most basal rate entries the pump can store, when it has a limit.
    public let maxBasalSegments: Int?
    public let carbRatio: ValueLimits
    public let sensitivity: ValueLimits
    public let target: ValueLimits
    /// The most entries a schedule can have.
    public let maxSegments: Int
    /// Schedule entries start at a multiple of this many seconds from midnight.
    public let segmentSeconds: Int

    public init(units: String, maxBasal: Double, basalRates: [Double], basalMinimum: Double? = nil, maxBasalSegments: Int? = nil, carbRatio: ValueLimits, sensitivity: ValueLimits, target: ValueLimits, maxSegments: Int, segmentSeconds: Int) {
        self.units = units
        self.maxBasal = maxBasal
        self.basalRates = basalRates
        self.basalMinimum = basalMinimum
        self.maxBasalSegments = maxBasalSegments
        self.carbRatio = carbRatio
        self.sensitivity = sensitivity
        self.target = target
        self.maxSegments = maxSegments
        self.segmentSeconds = segmentSeconds
    }

    public var dictionaryRepresentation: [String: Any] {
        var rval: [String: Any] = [
            "units": units,
            "maxBasal": maxBasal,
            "basalRates": basalRates,
            "carbRatio": carbRatio.dictionaryRepresentation,
            "sensitivity": sensitivity.dictionaryRepresentation,
            "target": target.dictionaryRepresentation,
            "maxSegments": maxSegments,
            "segmentSeconds": segmentSeconds,
        ]
        rval["basalMinimum"] = basalMinimum
        rval["maxBasalSegments"] = maxBasalSegments
        return rval
    }

    init?(rawValue: RawValue) {
        guard
            let units = rawValue["units"] as? String,
            let maxBasal = rawValue["maxBasal"] as? Double,
            let basalRates = rawValue["basalRates"] as? [Double],
            let carbRatioRaw = rawValue["carbRatio"] as? ValueLimits.RawValue,
            let carbRatio = ValueLimits(rawValue: carbRatioRaw),
            let sensitivityRaw = rawValue["sensitivity"] as? ValueLimits.RawValue,
            let sensitivity = ValueLimits(rawValue: sensitivityRaw),
            let targetRaw = rawValue["target"] as? ValueLimits.RawValue,
            let target = ValueLimits(rawValue: targetRaw),
            let maxSegments = rawValue["maxSegments"] as? Int,
            let segmentSeconds = rawValue["segmentSeconds"] as? Int
        else {
            return nil
        }

        self.units = units
        self.maxBasal = maxBasal
        self.basalRates = basalRates
        self.basalMinimum = rawValue["basalMinimum"] as? Double
        self.maxBasalSegments = rawValue["maxBasalSegments"] as? Int
        self.carbRatio = carbRatio
        self.sensitivity = sensitivity
        self.target = target
        self.maxSegments = maxSegments
        self.segmentSeconds = segmentSeconds
    }
}

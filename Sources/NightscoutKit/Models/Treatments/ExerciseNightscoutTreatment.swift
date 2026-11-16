//
//  ExerciseNightscoutTreatment.swift
//  NightscoutKit
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import Foundation

public class ExerciseNightscoutTreatment: NightscoutTreatment {

    public let duration: TimeInterval

    public init(timestamp: Date, enteredBy: String, duration: TimeInterval, notes: String? = nil, id: String? = nil, syncIdentifier: String? = nil) {
        self.duration = duration
        super.init(timestamp: timestamp, enteredBy: enteredBy, notes: notes, id: id, eventType: .exercise, syncIdentifier: syncIdentifier)
    }

    required public init?(_ entry: [String : Any]) {
        guard let durationMinutes = entry["duration"] as? Double else {
            return nil
        }
        self.duration = TimeInterval(minutes: durationMinutes)
        super.init(entry)
    }

    override public var dictionaryRepresentation: [String: Any] {
        var rval = super.dictionaryRepresentation
        rval["duration"] = duration.minutes
        return rval
    }
}

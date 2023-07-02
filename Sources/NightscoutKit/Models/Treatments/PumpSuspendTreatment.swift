//
//  PumpSuspendTreatment.swift
//  RileyLink
//
//  Created by Pete Schwamb on 3/27/17.
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import Foundation

public class PumpSuspendTreatment: NightscoutTreatment {

    public let duration: TimeInterval


    public init(timestamp: Date, enteredBy: String, duration: TimeInterval, id: String? = nil, syncIdentifier: String? = nil) {
        self.duration = duration
        super.init(timestamp: timestamp, enteredBy: enteredBy, id: id, eventType: .suspendPump, syncIdentifier: syncIdentifier)
    }

    required public init?(_ entry: [String : Any]) {
        if let durationMinutes = entry["duration"] as? Double {
            self.duration = TimeInterval(minutes: durationMinutes)
        } else {
            self.duration = 0
        }

        super.init(entry)
    }

    override public var dictionaryRepresentation: [String: Any] {
        var rval = super.dictionaryRepresentation
        rval["duration"] = duration.minutes
        return rval
    }

}

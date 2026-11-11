//
//  ProfileSwitchNightscoutTreatment.swift
//  NightscoutKit
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import Foundation

/// A switch to the store profile named `profile`, in effect until the next switch when `duration` is 0.
public class ProfileSwitchNightscoutTreatment: NightscoutTreatment {

    public let profile: String
    public let duration: TimeInterval

    public init(timestamp: Date, enteredBy: String, profile: String, duration: TimeInterval = 0, notes: String? = nil, id: String? = nil, syncIdentifier: String? = nil) {
        self.profile = profile
        self.duration = duration
        super.init(timestamp: timestamp, enteredBy: enteredBy, notes: notes, id: id, eventType: .profileSwitch, syncIdentifier: syncIdentifier)
    }

    required public init?(_ entry: [String: Any]) {
        guard let profile = entry["profile"] as? String else {
            return nil
        }
        self.profile = profile
        self.duration = TimeInterval(minutes: (entry["duration"] as? Double) ?? 0)
        super.init(entry)
    }

    override public var dictionaryRepresentation: [String: Any] {
        var rval = super.dictionaryRepresentation
        rval["profile"] = profile
        rval["duration"] = duration.minutes
        return rval
    }
}

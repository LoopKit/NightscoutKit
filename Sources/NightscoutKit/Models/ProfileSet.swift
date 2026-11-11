//
//  ProfileSet.swift
//  NightscoutKit
//

import Foundation

fileprivate let timeZoneMap = (-18...18).reduce(into: [String: String]()) { (dict, hour) in
    let from = TimeZone(secondsFromGMT: 3600 * hour)!.identifier
    let to = String(format: "ETC/GMT%+d", hour * -1)
    dict[from] = to
}

fileprivate let reverseTimeZoneMap = timeZoneMap.reduce(into: [String: String]()) { (dict, entry) in
    dict[entry.value] = entry.key
}

public class ProfileSet {
    public typealias RawValue = [String: Any]

    public typealias ProfileStore = [String: Profile]
    typealias ProfileStoreRawValue = [String: Profile.RawValue]
    
    public struct ScheduleItem {
        typealias RawValue = [String: Any]

        public let offset: TimeInterval
        public let value: Double
        
        public init(offset: TimeInterval, value: Double) {
            self.offset = offset
            self.value = value
        }
        
        public var dictionaryRepresentation: [String: Any] {
            var rep = [String: Any]()
            let hours = floor(offset.hours)
            let minutes = floor((offset - TimeInterval(hours: hours)).minutes)
            rep["time"] = String(format:"%02i:%02i", Int(hours), Int(minutes))
            rep["value"] = value
            rep["timeAsSeconds"] = Int(offset)
            return rep
        }

        init?(rawValue: RawValue) {
            guard
                let offset = (rawValue["timeAsSeconds"] as? Double) ?? (rawValue["time"] as? String).flatMap(Self.offset(fromTime:)),
                let value = rawValue["value"] as? Double
            else {
                return nil
            }

            self.offset = offset
            self.value = value
        }

        /// The offset of an "HH:mm" time.
        private static func offset(fromTime time: String) -> TimeInterval? {
            let parts = time.split(separator: ":")
            guard parts.count == 2, let hours = Int(parts[0]), let minutes = Int(parts[1]) else {
                return nil
            }
            return TimeInterval(hours: Double(hours)) + TimeInterval(minutes: Double(minutes))
        }
    }
    
    public struct Profile {
        typealias RawValue = [String: Any]

        public let timeZone: TimeZone
        public let dia: TimeInterval
        public let sensitivity: [ScheduleItem]
        public let carbratio: [ScheduleItem]
        public let basal: [ScheduleItem]
        public let targetLow: [ScheduleItem]
        public let targetHigh: [ScheduleItem]
        public let units: String?

        public init(timezone: TimeZone, dia: TimeInterval, sensitivity: [ScheduleItem], carbratio: [ScheduleItem], basal: [ScheduleItem], targetLow: [ScheduleItem], targetHigh: [ScheduleItem], units: String) {
            self.timeZone = timezone
            self.dia = dia
            self.sensitivity = sensitivity
            self.carbratio = carbratio
            self.basal = basal
            self.targetLow = targetLow
            self.targetHigh = targetHigh
            self.units = units
        }

        public var dictionaryRepresentation: [String: Any] {
            var rval: [String: Any] = [
                "dia": dia.hours,
                "carbs_hr": "0",
                "delay": "0",
                "timezone": timeZoneMap[timeZone.identifier] ?? timeZone.identifier,
                "target_low": targetLow.map { $0.dictionaryRepresentation },
                "target_high": targetHigh.map { $0.dictionaryRepresentation },
                "sens": sensitivity.map { $0.dictionaryRepresentation },
                "basal": basal.map { $0.dictionaryRepresentation },
                "carbratio": carbratio.map { $0.dictionaryRepresentation },
                ]
            rval["units"] = units
            return rval
        }

        init?(rawValue: RawValue) {
            guard
                let nsTimezoneIdentifier = rawValue["timezone"] as? String,
                let timeZone = TimeZone(identifier: reverseTimeZoneMap[nsTimezoneIdentifier] ?? nsTimezoneIdentifier),
                let diaHours = rawValue["dia"] as? Double,
                let sensitivityRaw = rawValue["sens"] as? [ScheduleItem.RawValue],
                let carbratioRaw = rawValue["carbratio"] as? [ScheduleItem.RawValue],
                let basalRaw = rawValue["basal"] as? [ScheduleItem.RawValue],
                let targetLowRaw = rawValue["target_low"] as? [ScheduleItem.RawValue],
                let targetHighRaw = rawValue["target_high"] as? [ScheduleItem.RawValue]
            else {
                return nil
            }

            self.timeZone = timeZone
            self.dia = TimeInterval(hours: diaHours)
            self.sensitivity = sensitivityRaw.compactMap { ScheduleItem(rawValue: $0) }
            self.carbratio = carbratioRaw.compactMap { ScheduleItem(rawValue: $0) }
            self.basal = basalRaw.compactMap { ScheduleItem(rawValue: $0) }
            self.targetLow = targetLowRaw.compactMap { ScheduleItem(rawValue: $0) }
            self.targetHigh = targetHighRaw.compactMap { ScheduleItem(rawValue: $0) }
            self.units = rawValue["units"] as? String
         }
    }
    
    public let startDate: Date
    public let units: String
    public let enteredBy: String
    public let defaultProfile: String
    public let store: ProfileStore
    /// Loop's settings, or nil for a profile set another uploader wrote.
    public let settings: LoopSettings?
    public let syncIdentifier: String
    public let isAPNSProduction: Bool?
    /// The uploader's time zone identifier, e.g. "America/Chicago". The profiles' own
    /// `timezone` is the fixed offset their schedules use.
    public let timeZone: String?
    /// The bounds a remote editor of the store's profiles must keep to.
    public let profileEditLimits: ProfileEditLimits?
    /// The remote commands the uploader accepts for the store's profiles, e.g. "profile-switch".
    public let remoteCommands: [String]?
    /// The weekly starts of the store's profiles.
    public let scheduledSwitches: [ScheduledSwitch]?
    /// The fingerprint of `scheduledSwitches` that a remote editor of the list sends back.
    public let scheduledSwitchesFingerprint: String?

    public init(startDate: Date, units: String, enteredBy: String, defaultProfile: String, store: ProfileStore, settings: LoopSettings?, syncIdentifier: String, isAPNSProduction: Bool? = nil, timeZone: String? = nil, profileEditLimits: ProfileEditLimits? = nil, remoteCommands: [String]? = nil, scheduledSwitches: [ScheduledSwitch]? = nil, scheduledSwitchesFingerprint: String? = nil) {
        self.startDate = startDate
        self.units = units
        self.enteredBy = enteredBy
        self.defaultProfile = defaultProfile
        self.store = store
        self.settings = settings
        self.syncIdentifier = syncIdentifier
        self.isAPNSProduction = isAPNSProduction
        self.timeZone = timeZone
        self.profileEditLimits = profileEditLimits
        self.remoteCommands = remoteCommands
        self.scheduledSwitches = scheduledSwitches
        self.scheduledSwitchesFingerprint = scheduledSwitchesFingerprint
    }
    
    public var dictionaryRepresentation: [String: Any] {
        let dateFormatter = ISO8601DateFormatter.defaultFormatter()
        let mills = String(format: "%.0f", startDate.timeIntervalSince1970.milliseconds)
        
        let dictProfiles = Dictionary(uniqueKeysWithValues:
            store.map { key, value in (key, value.dictionaryRepresentation) })
        
        var rval : [String: Any] = [
            "defaultProfile": defaultProfile,
            "startDate": dateFormatter.string(from: startDate),
            "mills": mills,
            "units": units,
            "enteredBy": enteredBy,
            "store": dictProfiles
        ]

        if let settings = settings {
            rval["loopSettings"] = settings.dictionaryRepresentation
        }

        if let isAPNSProduction = isAPNSProduction {
            rval["isAPNSProduction"] = isAPNSProduction
        }

        if let timeZone = timeZone {
            rval["timeZone"] = timeZone
        }

        if let profileEditLimits = profileEditLimits {
            rval["profileEditLimits"] = profileEditLimits.dictionaryRepresentation
        }

        if let remoteCommands = remoteCommands {
            rval["remoteCommands"] = remoteCommands
        }

        if let scheduledSwitches = scheduledSwitches {
            rval["scheduledSwitches"] = scheduledSwitches.map(\.dictionaryRepresentation)
        }

        if let scheduledSwitchesFingerprint = scheduledSwitchesFingerprint {
            rval["scheduledSwitchesFingerprint"] = scheduledSwitchesFingerprint
        }

        return rval
    }

    public init?(rawValue: RawValue) {
        guard
            let startDateStr = rawValue["startDate"] as? String,
            let startDate = TimeFormat.dateFromTimestamp(startDateStr),
            let units = rawValue["units"] as? String,
            let enteredBy = rawValue["enteredBy"] as? String,
            let defaultProfile = rawValue["defaultProfile"] as? String,
            let storeRaw = rawValue["store"] as? ProfileStoreRawValue,
            let syncIdentifier = rawValue["_id"] as? String
        else {
            return nil
        }

        self.startDate = startDate
        self.units = units
        self.enteredBy = enteredBy
        self.defaultProfile = defaultProfile
        self.store = storeRaw.compactMapValues { Profile(rawValue: $0) }
        self.settings = (rawValue["loopSettings"] as? LoopSettings.RawValue).flatMap { LoopSettings(rawValue: $0) }
        self.syncIdentifier = syncIdentifier
        self.isAPNSProduction = rawValue["isAPNSProduction"] as? Bool
        self.timeZone = rawValue["timeZone"] as? String
        self.profileEditLimits = (rawValue["profileEditLimits"] as? ProfileEditLimits.RawValue).flatMap { ProfileEditLimits(rawValue: $0) }
        self.remoteCommands = rawValue["remoteCommands"] as? [String]
        self.scheduledSwitches = (rawValue["scheduledSwitches"] as? [ScheduledSwitch.RawValue])?.compactMap { ScheduledSwitch(rawValue: $0) }
        self.scheduledSwitchesFingerprint = rawValue["scheduledSwitchesFingerprint"] as? String
    }
}

extension ProfileSet {
    /// A weekly start of the store profile named `profile`, `time` seconds after midnight in the profiles' time zone
    /// on `weekday` (1–7, Sunday = 1). It stays active until the next start.
    public struct ScheduledSwitch: Equatable {
        typealias RawValue = [String: Any]

        public let id: String
        public let profile: String
        public let weekday: Int
        public let time: Int
        /// A paused start does not run.
        public let paused: Bool

        public init(id: String, profile: String, weekday: Int, time: Int, paused: Bool = false) {
            self.id = id
            self.profile = profile
            self.weekday = weekday
            self.time = time
            self.paused = paused
        }

        public var dictionaryRepresentation: [String: Any] {
            var rval: [String: Any] = [
                "id": id,
                "profile": profile,
                "weekday": weekday,
                "time": time,
            ]
            if paused {
                rval["paused"] = true
            }
            return rval
        }

        init?(rawValue: RawValue) {
            guard
                let id = rawValue["id"] as? String,
                let profile = rawValue["profile"] as? String,
                let weekday = rawValue["weekday"] as? Int,
                let time = rawValue["time"] as? Int
            else {
                return nil
            }
            self.id = id
            self.profile = profile
            self.weekday = weekday
            self.time = time
            self.paused = rawValue["paused"] as? Bool ?? false
        }
    }
}

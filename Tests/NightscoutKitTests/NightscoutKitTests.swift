import XCTest
@testable import NightscoutKit

final class NightscoutKitTests: XCTestCase {
    func testFixedOffsetTimezoneIdentifierConversion() {
        // This verifies that fixed offset timezones are encoded in a moment.js compatibile way
        // I.e. GMT-0500 -> "ETC/GMT+5"

        let timeZone = TimeZone(secondsFromGMT: -5 * 60 * 60)! // GMT-0500 (fixed)
        let isfSchedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 85)]
        let carbRatioSchedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 12)]
        let basalSchedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 1.2)]
        let targetLowSchedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 100)]
        let targetHighSchedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 110)]
        let profile = ProfileSet.Profile(timezone: timeZone, dia: .hours(6), sensitivity: isfSchedule, carbratio: carbRatioSchedule, basal: basalSchedule, targetLow: targetLowSchedule, targetHigh: targetHighSchedule, units: "mg/dL")

        let json = profile.dictionaryRepresentation

        XCTAssertEqual("ETC/GMT+5", json["timezone"] as? String)
    }

    private func makeProfileSet(isAPNSProduction: Bool?, timeZone profileSetTimeZone: String? = nil) -> ProfileSet {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let schedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 1)]
        let profile = ProfileSet.Profile(timezone: timeZone, dia: .hours(6), sensitivity: schedule, carbratio: schedule, basal: schedule, targetLow: schedule, targetHigh: schedule, units: "mg/dL")
        let settings = LoopSettings(dosingEnabled: true, overridePresets: [], scheduleOverride: nil, minimumBGGuard: nil, preMealTargetRange: nil, maximumBasalRatePerHour: nil, maximumBolus: nil, deviceToken: "token", bundleIdentifier: "com.example.loop", dosingStrategy: "automaticBolus")
        return ProfileSet(startDate: Date(), units: "mg/dL", enteredBy: "Loop", defaultProfile: "Default", store: ["Default": profile], settings: settings, syncIdentifier: "sync", isAPNSProduction: isAPNSProduction, timeZone: profileSetTimeZone)
    }

    func testAPNSProductionEnvironmentIsSerializedAtTopLevel() {
        XCTAssertEqual(true, makeProfileSet(isAPNSProduction: true).dictionaryRepresentation["isAPNSProduction"] as? Bool)
        XCTAssertEqual(false, makeProfileSet(isAPNSProduction: false).dictionaryRepresentation["isAPNSProduction"] as? Bool)
    }

    func testAPNSProductionEnvironmentOmittedWhenUnset() {
        XCTAssertNil(makeProfileSet(isAPNSProduction: nil).dictionaryRepresentation["isAPNSProduction"])
    }

    func testProfileSetTimeZoneIsSerializedAtTopLevel() {
        let json = makeProfileSet(isAPNSProduction: nil, timeZone: "America/Chicago").dictionaryRepresentation
        XCTAssertEqual("America/Chicago", json["timeZone"] as? String)
        XCTAssertNil(makeProfileSet(isAPNSProduction: nil).dictionaryRepresentation["timeZone"])
    }

    func testUploaderTimeZone() {
        let status = UploaderStatus(name: "phone", timestamp: Date(), battery: 50, timeZone: "America/Chicago")
        XCTAssertEqual("America/Chicago", status.dictionaryRepresentation["timeZone"] as? String)
        XCTAssertNil(UploaderStatus(name: "phone", timestamp: Date(), battery: 50).dictionaryRepresentation["timeZone"])
    }

    func testBolusCalculationRoundTrip() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let calculation = BolusCalculation(requested: 2.5, recommended: 3.05, recommendationDate: date, carbs: 30, carbsDate: date, carbSyncIdentifier: "carb", glucose: 154, glucoseDate: date)
        let json = LoopStatus(name: "Loop", version: "1", timestamp: date, bolusCalculation: calculation).dictionaryRepresentation
        let raw = json["bolusCalculation"] as? [String: Any]
        XCTAssertEqual(2.5, raw?["requested"] as? Double)
        let decoded = LoopStatus(rawValue: json)?.bolusCalculation
        XCTAssertEqual(3.05, decoded?.recommended)
        XCTAssertEqual("carb", decoded?.carbSyncIdentifier)
        XCTAssertEqual(date, decoded?.glucoseDate)
        XCTAssertNil(LoopStatus(name: "Loop", version: "1", timestamp: date).dictionaryRepresentation["bolusCalculation"])
    }

    func testFailureCodeRoundTrip() {
        let status = LoopStatus(name: "Loop", version: "1", timestamp: Date(), failureReason: "pumpDataTooOld[\"date\": \"x\"]", failureCode: "pumpDataTooOld")
        let json = status.dictionaryRepresentation
        XCTAssertEqual("pumpDataTooOld", json["failureCode"] as? String)
        XCTAssertEqual("pumpDataTooOld", LoopStatus(rawValue: json)?.failureCode)
    }

    func testProfileEditLimitsAreSerializedAtTopLevel() throws {
        let limits = ProfileEditLimits(
            units: "mg/dL",
            maxBasal: 3.0,
            basalRates: [0.05, 0.1, 0.15],
            maxBasalSegments: 24,
            carbRatio: .init(min: 2, max: 150, step: 0.1, recommendedMin: 4, recommendedMax: 28),
            sensitivity: .init(min: 10, max: 500, step: 1, recommendedMin: 16, recommendedMax: 399),
            target: .init(min: 87, max: 180, step: 1),
            maxSegments: 48,
            segmentSeconds: 1800)
        let schedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 1)]
        let profile = ProfileSet.Profile(timezone: TimeZone(secondsFromGMT: 0)!, dia: .hours(6), sensitivity: schedule, carbratio: schedule, basal: schedule, targetLow: schedule, targetHigh: schedule, units: "mg/dL")
        let settings = LoopSettings(dosingEnabled: true, overridePresets: [], scheduleOverride: nil, minimumBGGuard: nil, preMealTargetRange: nil, maximumBasalRatePerHour: nil, maximumBolus: nil, deviceToken: "token", bundleIdentifier: "com.example.loop", dosingStrategy: "automaticBolus")
        let profileSet = ProfileSet(startDate: Date(), units: "mg/dL", enteredBy: "Loop", defaultProfile: "Sport", store: ["Default": profile, "Sport": profile], settings: settings, syncIdentifier: "sync", profileEditLimits: limits)

        var json = profileSet.dictionaryRepresentation
        let limitsJSON = try XCTUnwrap(json["profileEditLimits"] as? [String: Any])
        XCTAssertEqual(limitsJSON["maxBasal"] as? Double, 3.0)
        XCTAssertEqual(limitsJSON["segmentSeconds"] as? Int, 1800)
        XCTAssertEqual((limitsJSON["carbRatio"] as? [String: Any])?["recommendedMax"] as? Double, 28)
        XCTAssertNil((limitsJSON["target"] as? [String: Any])?["recommendedMin"])
        XCTAssertNil(limitsJSON["basalMinimum"])

        json["_id"] = "sync"
        XCTAssertEqual(ProfileSet(rawValue: json)?.profileEditLimits, limits)
        XCTAssertNil(makeProfileSet(isAPNSProduction: nil).dictionaryRepresentation["profileEditLimits"])
    }

    func testRemoteCommandsAreSerializedAtTopLevel() {
        let schedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 1)]
        let profile = ProfileSet.Profile(timezone: TimeZone(secondsFromGMT: 0)!, dia: .hours(6), sensitivity: schedule, carbratio: schedule, basal: schedule, targetLow: schedule, targetHigh: schedule, units: "mg/dL")
        let commands = ["profile-switch", "profile-save", "profile-delete"]
        let profileSet = ProfileSet(startDate: Date(), units: "mg/dL", enteredBy: "Loop", defaultProfile: "Default", store: ["Default": profile], settings: nil, syncIdentifier: "sync", remoteCommands: commands)

        var json = profileSet.dictionaryRepresentation
        XCTAssertEqual(json["remoteCommands"] as? [String], commands)
        json["_id"] = "sync"
        XCTAssertEqual(ProfileSet(rawValue: json)?.remoteCommands, commands)

        var withoutCommands = makeProfileSet(isAPNSProduction: nil).dictionaryRepresentation
        XCTAssertNil(withoutCommands["remoteCommands"])
        withoutCommands["_id"] = "sync"
        XCTAssertNil(ProfileSet(rawValue: withoutCommands)?.remoteCommands)
    }

    func testScheduledSwitchesAreSerializedAtTopLevel() throws {
        let schedule = [ProfileSet.ScheduleItem(offset: .hours(0), value: 1)]
        let profile = ProfileSet.Profile(timezone: TimeZone(secondsFromGMT: 0)!, dia: .hours(6), sensitivity: schedule, carbratio: schedule, basal: schedule, targetLow: schedule, targetHigh: schedule, units: "mg/dL")
        let switches = [
            ProfileSet.ScheduledSwitch(id: "A", profile: "Weekend", weekday: 7, time: 25200, paused: true),
            ProfileSet.ScheduledSwitch(id: "B", profile: "Default", weekday: 2, time: 21600),
        ]
        let profileSet = ProfileSet(startDate: Date(), units: "mg/dL", enteredBy: "Loop", defaultProfile: "Default", store: ["Default": profile, "Weekend": profile], settings: nil, syncIdentifier: "sync", scheduledSwitches: switches, scheduledSwitchesFingerprint: "1f4d16404c846d2f")

        var json = profileSet.dictionaryRepresentation
        let entries = try XCTUnwrap(json["scheduledSwitches"] as? [[String: Any]])
        XCTAssertEqual(entries[0]["paused"] as? Bool, true)
        XCTAssertNil(entries[1]["paused"])
        XCTAssertEqual(entries[1]["time"] as? Int, 21600)
        XCTAssertEqual(json["scheduledSwitchesFingerprint"] as? String, "1f4d16404c846d2f")
        json["_id"] = "sync"
        let decoded = try XCTUnwrap(ProfileSet(rawValue: json))
        XCTAssertEqual(decoded.scheduledSwitches, switches)
        XCTAssertEqual(decoded.scheduledSwitchesFingerprint, "1f4d16404c846d2f")

        var withoutSwitches = makeProfileSet(isAPNSProduction: nil).dictionaryRepresentation
        XCTAssertNil(withoutSwitches["scheduledSwitches"])
        XCTAssertNil(withoutSwitches["scheduledSwitchesFingerprint"])
        withoutSwitches["_id"] = "sync"
        XCTAssertNil(ProfileSet(rawValue: withoutSwitches)?.scheduledSwitches)
    }

    func testProfileSwitchTreatmentRoundTrips() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let treatment = ProfileSwitchNightscoutTreatment(timestamp: date, enteredBy: "Loop", profile: "Sport")
        var json = treatment.dictionaryRepresentation
        XCTAssertEqual(json["eventType"] as? String, "Profile Switch")
        XCTAssertEqual(json["profile"] as? String, "Sport")
        XCTAssertEqual(json["duration"] as? Double, 0)

        json["_id"] = "abc"
        let parsed = try XCTUnwrap(NightscoutTreatment.fromServer(json) as? ProfileSwitchNightscoutTreatment)
        XCTAssertEqual(parsed.profile, "Sport")
        XCTAssertEqual(parsed.duration, 0)
        XCTAssertEqual(parsed.timestamp, date)
    }

    func testProfileSetFromAnotherUploader() throws {
        let json = """
        {"_id": "6720d2c1a1b2c3d4e5f60718", "defaultProfile": "Sport", "startDate": "2026-11-07T12:00:00.000Z", "mills": 1793966400000,
         "units": "mmol", "enteredBy": "Trio", "bundleIdentifier": "org.nightscout.trio", "deviceToken": "token", "isAPNSProduction": false, "teamID": "TEAM",
         "store": {
           "default": {"dia": 6, "carbs_hr": 20, "delay": 0, "timezone": "Europe/Stockholm", "units": "mmol",
                       "basal": [{"time": "00:00", "value": 0.85, "timeAsSeconds": 0}, {"time": "06:00", "value": 1.0, "timeAsSeconds": 21600}],
                       "carbratio": [{"time": "00:00", "value": 10, "timeAsSeconds": 0}],
                       "sens": [{"time": "00:00", "value": 2.8, "timeAsSeconds": 0}],
                       "target_low": [{"time": "00:00", "value": 5.6, "timeAsSeconds": 0}],
                       "target_high": [{"time": "00:00", "value": 6.1, "timeAsSeconds": 0}]},
           "Sport": {"dia": 6, "carbs_hr": 20, "delay": 0, "timezone": "Europe/Stockholm", "units": "mmol",
                     "basal": [{"time": "00:00", "value": 0.5}],
                     "carbratio": [{"time": "00:00", "value": 12}],
                     "sens": [{"time": "00:00", "value": 3.3}],
                     "target_low": [{"time": "00:00", "value": 6.7}],
                     "target_high": [{"time": "00:00", "value": 7.2}]}
         }}
        """
        let raw = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let profileSet = try XCTUnwrap(ProfileSet(rawValue: raw))
        XCTAssertNil(profileSet.settings)
        XCTAssertEqual(profileSet.defaultProfile, "Sport")
        XCTAssertEqual(Set(profileSet.store.keys), ["default", "Sport"])
        let defaultProfile = try XCTUnwrap(profileSet.store["default"])
        XCTAssertEqual(defaultProfile.timeZone.identifier, "Europe/Stockholm")
        XCTAssertEqual(defaultProfile.basal.map(\.offset), [0, 21600])
        XCTAssertEqual(profileSet.store["Sport"]?.targetHigh.first?.value, 7.2)
        XCTAssertNil(profileSet.dictionaryRepresentation["loopSettings"])
    }
}

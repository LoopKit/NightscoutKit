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
}

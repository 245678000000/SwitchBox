import Foundation
import CoreLocation

// MARK: - 深色模式计划

enum DarkScheduleMode: String, CaseIterable, Identifiable {
    case manual, sun, custom
    var id: String { rawValue }
    var title: String {
        switch self {
        case .manual: String(localized: "手动开关")
        case .sun: String(localized: "根据日出日落自动开关")
        case .custom: String(localized: "自定时间")
        }
    }
}

func formatMinutes(_ m: Int) -> String {
    String(format: "%02d:%02d", (m / 60) % 24, m % 60)
}

// MARK: - 日出日落计算（NOAA 简化算法）

enum Solar {
    /// 返回当地当天的日出、日落时间；极昼/极夜返回 nil
    static func sunTimes(on date: Date = Date(), latitude lat: Double, longitude lon: Double) -> (sunrise: Date, sunset: Date)? {
        guard let rise = calc(date, lat, lon, rising: true),
              let set = calc(date, lat, lon, rising: false) else { return nil }
        return (rise, set)
    }

    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }
    private static func norm(_ v: Double, _ m: Double) -> Double { let r = v.truncatingRemainder(dividingBy: m); return r < 0 ? r + m : r }

    private static func calc(_ date: Date, _ lat: Double, _ lon: Double, rising: Bool) -> Date? {
        let local = Calendar.current
        let n = Double(local.ordinality(of: .day, in: .year, for: date) ?? 1)
        let lngHour = lon / 15
        let t = n + ((rising ? 6 : 18) - lngHour) / 24
        let m = 0.9856 * t - 3.289
        let l = norm(m + 1.916 * sin(rad(m)) + 0.020 * sin(rad(2 * m)) + 282.634, 360)
        var ra = norm(deg(atan(0.91764 * tan(rad(l)))), 360)
        ra += floor(l / 90) * 90 - floor(ra / 90) * 90
        ra /= 15
        let sinDec = 0.39782 * sin(rad(l))
        let cosDec = cos(asin(sinDec))
        let cosH = (cos(rad(90.833)) - sinDec * sin(rad(lat))) / (cosDec * cos(rad(lat)))
        guard cosH >= -1, cosH <= 1 else { return nil }
        let h = (rising ? 360 - deg(acos(cosH)) : deg(acos(cosH))) / 15
        let localMeanTime = h + ra - 0.06571 * t - 6.622
        let ut = norm(localMeanTime - lngHour, 24)

        // 以当地日期的 UTC 零点为基准，再挪到当地当天范围内
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let comps = local.dateComponents([.year, .month, .day], from: date)
        guard let base = utc.date(from: comps) else { return nil }
        var result = base.addingTimeInterval(ut * 3600)
        let dayStart = local.startOfDay(for: date)
        let dayEnd = dayStart.addingTimeInterval(86400)
        while result < dayStart { result += 86400 }
        while result >= dayEnd { result -= 86400 }
        return result
    }
}

// MARK: - 位置（仅用于计算日出日落）

final class LocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = LocationProvider()
    private let manager = CLLocationManager()
    var onUpdate: (() -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    /// 已保存的坐标；没有时按时区粗略估算
    var coordinate: (lat: Double, lon: Double, precise: Bool) {
        let d = UserDefaults.standard
        if d.object(forKey: "loc.lat") != nil {
            return (d.double(forKey: "loc.lat"), d.double(forKey: "loc.lon"), true)
        }
        let lon = Double(TimeZone.current.secondsFromGMT()) / 3600 * 15
        return (35, lon, false)
    }

    var authorization: CLAuthorizationStatus { manager.authorizationStatus }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .denied, .restricted: break
        default: manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorized {
            manager.requestLocation()
        }
        onUpdate?()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        UserDefaults.standard.set(c.latitude, forKey: "loc.lat")
        UserDefaults.standard.set(c.longitude, forKey: "loc.lon")
        onUpdate?()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("[SwitchBox] location error: \(error)")
    }
}

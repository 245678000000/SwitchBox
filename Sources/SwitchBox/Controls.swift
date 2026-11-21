import AppKit
import IOKit.pwr_mgt
import CoreWLAN

// MARK: - 小工具

@discardableResult
func runAppleScript(_ source: String) -> NSAppleEventDescriptor? {
    var error: NSDictionary?
    let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
    if let error { NSLog("[SwitchBox] AppleScript error: \(error)") }
    return result
}

@discardableResult
func shell(_ path: String, _ args: [String]) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    do { try p.run(); p.waitUntilExit(); return p.terminationStatus } catch { return -1 }
}

func readPref(_ key: String, domain: String) -> Any? {
    let d = domain as CFString
    CFPreferencesAppSynchronize(d)
    return CFPreferencesCopyAppValue(key as CFString, d)
}

func readGlobalPref(_ key: String) -> Any? {
    CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
    return CFPreferencesCopyAppValue(key as CFString, kCFPreferencesAnyApplication)
}

func boolValue(_ v: Any?) -> Bool? {
    if let b = v as? Bool { return b }
    if let n = v as? NSNumber { return n.boolValue }
    if let s = v as? String { return ["1", "true", "yes"].contains(s.lowercased()) }
    return nil
}

// MARK: - 访达相关（隐藏桌面 / 显示隐藏文件）

enum Finder {
    static var desktopHidden: Bool {
        boolValue(readPref("CreateDesktop", domain: "com.apple.finder")) == false
    }
    static func setDesktopHidden(_ hidden: Bool) {
        shell("/usr/bin/defaults", ["write", "com.apple.finder", "CreateDesktop", "-bool", hidden ? "false" : "true"])
        shell("/usr/bin/killall", ["Finder"])
    }

    static var showsHiddenFiles: Bool {
        boolValue(readPref("AppleShowAllFiles", domain: "com.apple.finder")) == true
    }
    static func setShowsHiddenFiles(_ show: Bool) {
        shell("/usr/bin/defaults", ["write", "com.apple.finder", "AppleShowAllFiles", "-bool", show ? "true" : "false"])
        shell("/usr/bin/killall", ["Finder"])
    }
}

// MARK: - 外观 / 程序坞 / 菜单栏（通过“系统事件”）

enum Appearance {
    static var isDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    static func setDark(_ on: Bool) {
        runAppleScript("tell application \"System Events\" to tell appearance preferences to set dark mode to \(on)")
    }

    static var dockAutohide: Bool {
        boolValue(readPref("autohide", domain: "com.apple.dock")) == true
    }
    static func setDockAutohide(_ on: Bool) {
        runAppleScript("tell application \"System Events\" to set autohide of dock preferences to \(on)")
    }

    static var menuBarAutohide: Bool {
        boolValue(readGlobalPref("_HIHideMenuBar")) == true
    }
    static func setMenuBarAutohide(_ on: Bool) {
        runAppleScript("tell application \"System Events\" to set autohide menu bar of dock preferences to \(on)")
    }
}

// MARK: - 保持亮屏（IOKit 电源断言）

final class KeepAwake {
    private var assertionID: IOPMAssertionID = 0
    private var timer: Timer?
    private(set) var endDate: Date?
    var onExpire: (() -> Void)?

    var isOn: Bool { assertionID != 0 }

    /// minutes == 0 表示永久
    func start(minutes: Int) {
        stop()
        let r = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "SwitchBox 保持亮屏" as CFString,
            &assertionID)
        guard r == kIOReturnSuccess else { assertionID = 0; return }
        if minutes > 0 {
            endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
                self?.stop()
                self?.onExpire?()
            }
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil; endDate = nil
        if assertionID != 0 { IOPMAssertionRelease(assertionID); assertionID = 0 }
    }
}

// MARK: - 夜览（私有框架 CoreBrightness）

final class NightShift {
    private let client: NSObject?

    init() {
        dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW)
        if let cls = NSClassFromString("CBBlueLightClient") as? NSObject.Type {
            client = cls.init()
        } else {
            client = nil
        }
    }

    var isAvailable: Bool { client != nil }

    var isOn: Bool {
        guard let client else { return false }
        let sel = NSSelectorFromString("getBlueLightStatus:")
        guard client.responds(to: sel) else { return false }
        typealias Fn = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool
        let fn = unsafeBitCast(client.method(for: sel), to: Fn.self)
        // struct { BOOL active; BOOL enabled; BOOL sunSchedulePermitted; int mode; ... }
        let buf = UnsafeMutableRawPointer.allocate(byteCount: 256, alignment: 8)
        defer { buf.deallocate() }
        memset(buf, 0, 256)
        guard fn(client, sel, buf) else { return false }
        return buf.load(fromByteOffset: 1, as: Bool.self)
    }

    /// 0 = 手动, 1 = 日落到日出, 2 = 自定时间
    var mode: Int32 {
        guard let client else { return 0 }
        let sel = NSSelectorFromString("getBlueLightStatus:")
        guard client.responds(to: sel) else { return 0 }
        typealias Fn = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool
        let fn = unsafeBitCast(client.method(for: sel), to: Fn.self)
        let buf = UnsafeMutableRawPointer.allocate(byteCount: 256, alignment: 8)
        defer { buf.deallocate() }
        memset(buf, 0, 256)
        guard fn(client, sel, buf) else { return 0 }
        return buf.load(fromByteOffset: 4, as: Int32.self)
    }

    func setMode(_ mode: Int32) {
        guard let client else { return }
        let sel = NSSelectorFromString("setMode:")
        guard client.responds(to: sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, Int32) -> Bool
        _ = unsafeBitCast(client.method(for: sel), to: Fn.self)(client, sel, mode)
    }

    func set(_ on: Bool) {
        guard let client else { return }
        let sel = NSSelectorFromString("setEnabled:")
        guard client.responds(to: sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, Bool) -> Bool
        let fn = unsafeBitCast(client.method(for: sel), to: Fn.self)
        _ = fn(client, sel, on)
    }
}

// MARK: - 屏幕保护

enum ScreenSaver {
    static func start() {
        let url = URL(fileURLWithPath: "/System/Library/CoreServices/ScreenSaverEngine.app")
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }
}

// MARK: - 麦克风静音

enum Microphone {
    private static let savedKey = "mic.savedVolume"

    static var inputVolume: Int? {
        runAppleScript("input volume of (get volume settings)").map { Int($0.int32Value) }
    }
    static var isMuted: Bool { inputVolume == 0 }

    static func setMuted(_ muted: Bool) {
        if muted {
            if let v = inputVolume, v > 0 { UserDefaults.standard.set(v, forKey: savedKey) }
            runAppleScript("set volume input volume 0")
        } else {
            let v = UserDefaults.standard.integer(forKey: savedKey)
            runAppleScript("set volume input volume \(v > 0 ? v : 75)")
        }
    }
}

// MARK: - 废纸篓

enum Trash {
    /// nil 表示无权限读取（需要“完全磁盘访问权限”）
    static var itemCount: Int? {
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: path) else { return nil }
        return items.filter { $0 != ".DS_Store" && $0 != ".localized" }.count
    }
    static func empty() {
        runAppleScript("tell application \"Finder\" to empty trash")
    }
}

// MARK: - 推出磁盘

enum Disks {
    static func ejectable(excluding excluded: [String] = []) -> [URL] {
        all.filter { !excluded.contains($0.path) }
    }

    /// 所有可推出的卷（不含排除）
    static var all: [URL] {
        let keys: [URLResourceKey] = [.volumeIsEjectableKey, .volumeIsRemovableKey, .volumeIsInternalKey]
        let vols = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return vols.filter { url in
            guard url.path.hasPrefix("/Volumes/"),
                  let v = try? url.resourceValues(forKeys: Set(keys)) else { return false }
            return v.volumeIsEjectable == true || v.volumeIsRemovable == true || v.volumeIsInternal == false
        }
    }
    static func ejectAll(excluding excluded: [String], completion: @escaping (Int) -> Void) {
        let vols = ejectable(excluding: excluded)
        DispatchQueue.global().async {
            var failed = 0
            for url in vols {
                do { try NSWorkspace.shared.unmountAndEjectDevice(at: url) } catch { failed += 1 }
            }
            DispatchQueue.main.async { completion(failed) }
        }
    }
}

// MARK: - 权限检测

enum PermissionStatus { case granted, denied, notDetermined, unknown }

enum Permissions {
    /// 检测/请求对某个 App 的“自动化”权限。ask = true 时会弹出系统授权框（会阻塞，请在后台线程调用）。
    static func automation(_ bundleID: String, ask: Bool) -> PermissionStatus {
        if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = false
            cfg.hides = true
            let sem = DispatchSemaphore(value: 0)
            NSWorkspace.shared.openApplication(at: url, configuration: cfg) { _, _ in sem.signal() }
            _ = sem.wait(timeout: .now() + 3)
        }
        let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
        guard let desc = target.aeDesc else { return .unknown }
        let status = AEDeterminePermissionToAutomateTarget(desc, typeWildCard, typeWildCard, ask)
        switch status {
        case noErr: return .granted
        case OSStatus(errAEEventNotPermitted): return .denied
        case OSStatus(errAEEventWouldRequireUserConsent): return .notDetermined
        default: return .unknown
        }
    }

    static var fullDiskAccess: PermissionStatus { Trash.itemCount != nil ? .granted : .denied }

    static func openAutomationSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }
    static func openFullDiskSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
    }
}

// MARK: - 原彩显示（私有框架 CoreBrightness）

final class TrueTone {
    private let client: NSObject?

    init() {
        dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW)
        client = (NSClassFromString("CBTrueToneClient") as? NSObject.Type)?.init()
    }

    private func getBool(_ name: String) -> Bool {
        guard let client else { return false }
        let sel = NSSelectorFromString(name)
        guard client.responds(to: sel) else { return false }
        typealias Fn = @convention(c) (AnyObject, Selector) -> Bool
        return unsafeBitCast(client.method(for: sel), to: Fn.self)(client, sel)
    }

    var isAvailable: Bool { getBool("supported") && getBool("available") }
    var isOn: Bool { getBool("enabled") }

    func set(_ on: Bool) {
        guard let client else { return }
        let sel = NSSelectorFromString("setEnabled:")
        guard client.responds(to: sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, Bool) -> Bool
        _ = unsafeBitCast(client.method(for: sel), to: Fn.self)(client, sel, on)
    }
}

// MARK: - 低电量模式（pmset，需要管理员密码）

enum LowPower {
    /// nil 表示不支持
    static var state: Bool? {
        let p = Process()
        let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["-g"]
        p.standardOutput = pipe
        do { try p.run() } catch { return nil }
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        p.waitUntilExit()
        guard let line = out.split(separator: "\n").first(where: { $0.contains("lowpowermode") || $0.contains("powermode") }) else { return nil }
        return line.trimmingCharacters(in: .whitespaces).hasSuffix("1")
    }
    static func set(_ on: Bool) {
        let prompt = String(localized: "SwitchBox 需要管理员权限来切换低电量模式。")
        runAppleScript("do shell script \"/usr/bin/pmset -a lowpowermode \(on ? 1 : 0)\" with prompt \"\(prompt)\" with administrator privileges")
    }
}

// MARK: - 静音

enum Speaker {
    static var isMuted: Bool {
        runAppleScript("output muted of (get volume settings)")?.booleanValue ?? false
    }
    static func setMuted(_ on: Bool) {
        runAppleScript("set volume output muted \(on)")
    }
}

// MARK: - Wi-Fi


enum WiFi {
    static var interface: CWInterface? { CWWiFiClient.shared().interface() }
    static var isAvailable: Bool { interface != nil }
    static var isOn: Bool { interface?.powerOn() ?? false }
    static var ssid: String? { interface?.ssid() }
    static func set(_ on: Bool) {
        try? interface?.setPower(on)
    }
}

// MARK: - 蓝牙（IOBluetooth 私有函数）

enum Bluetooth {
    private typealias Getter = @convention(c) () -> Int32
    private typealias Setter = @convention(c) (Int32) -> Void
    private static let handle = dlopen("/System/Library/Frameworks/IOBluetooth.framework/IOBluetooth", RTLD_NOW)
    private static let getter: Getter? = dlsym(handle, "IOBluetoothPreferenceGetControllerPowerState").map { unsafeBitCast($0, to: Getter.self) }
    private static let setter: Setter? = dlsym(handle, "IOBluetoothPreferenceSetControllerPowerState").map { unsafeBitCast($0, to: Setter.self) }

    static var isAvailable: Bool { getter != nil && setter != nil }
    static var isOn: Bool { (getter?() ?? 0) != 0 }
    static func set(_ on: Bool) { setter?(on ? 1 : 0) }
}

// MARK: - 隐藏窗口

enum WindowHider {
    private static var hiddenPIDs: [pid_t] = []
    static var isOn: Bool { !hiddenPIDs.isEmpty }

    static func set(_ on: Bool) {
        if on {
            let me = ProcessInfo.processInfo.processIdentifier
            let apps = NSWorkspace.shared.runningApplications.filter {
                $0.activationPolicy == .regular && !$0.isHidden && $0.processIdentifier != me
            }
            hiddenPIDs = apps.map(\.processIdentifier)
            apps.forEach { $0.hide() }
        } else {
            for pid in hiddenPIDs { NSRunningApplication(processIdentifier: pid)?.unhide() }
            hiddenPIDs.removeAll()
        }
    }
}

// MARK: - 锁定屏幕 / 显示器休眠

enum ScreenLock {
    private typealias Fn = @convention(c) () -> Int32
    static func lock() {
        let h = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_NOW)
        if let sym = dlsym(h, "SACLockScreenImmediate") {
            _ = unsafeBitCast(sym, to: Fn.self)()
        } else {
            sleepDisplay()
        }
    }
    static func sleepDisplay() {
        shell("/usr/bin/pmset", ["displaysleepnow"])
    }
}

// MARK: - 剪贴板

enum Clipboard {
    static func clear() { NSPasteboard.general.clearContents() }
}

// MARK: - Xcode 缓存（DerivedData）

enum XcodeCache {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Developer/Xcode/DerivedData")

    static func size() -> Int64 {
        guard let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
                                                     options: [], errorHandler: nil) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in e {
            total += Int64((try? f.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize) ?? 0)
        }
        return total
    }

    static func clean() {
        let items = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        items.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

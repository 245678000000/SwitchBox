import SwiftUI
import ServiceManagement

enum SwitchID: String, CaseIterable, Identifiable, Codable {
    case hideDesktop, darkMode, keepAwake, screenSaver, nightShift, screenClean,
         emptyTrash, ejectDisks, micMute, dockAutohide, menuBarAutohide, showHiddenFiles,
         trueTone, lowPower, outputMute, wifi, bluetooth, hideWindows,
         lockScreen, displaySleep, clearClipboard, xcodeCache

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hideDesktop: String(localized: "隐藏桌面图标")
        case .darkMode: String(localized: "深色模式")
        case .keepAwake: String(localized: "保持亮屏")
        case .screenSaver: String(localized: "屏幕保护")
        case .nightShift: String(localized: "夜览")
        case .screenClean: String(localized: "屏幕清洁")
        case .emptyTrash: String(localized: "清空废纸篓")
        case .ejectDisks: String(localized: "推出磁盘")
        case .micMute: String(localized: "麦克风静音")
        case .dockAutohide: String(localized: "自动隐藏程序坞")
        case .menuBarAutohide: String(localized: "自动隐藏菜单栏")
        case .showHiddenFiles: String(localized: "显示隐藏文件")
        case .trueTone: String(localized: "原彩显示")
        case .lowPower: String(localized: "低电量模式")
        case .outputMute: String(localized: "静音")
        case .wifi: "Wi‑Fi"
        case .bluetooth: String(localized: "蓝牙")
        case .hideWindows: String(localized: "隐藏窗口")
        case .lockScreen: String(localized: "锁定屏幕")
        case .displaySleep: String(localized: "显示器休眠")
        case .clearClipboard: String(localized: "清空剪贴板")
        case .xcodeCache: String(localized: "清理 Xcode 缓存")
        }
    }

    var symbol: String {
        switch self {
        case .hideDesktop: "menubar.dock.rectangle"
        case .darkMode: "moon.stars.fill"
        case .keepAwake: "cup.and.saucer.fill"
        case .screenSaver: "sparkles.tv.fill"
        case .nightShift: "sun.horizon.fill"
        case .screenClean: "bubbles.and.sparkles.fill"
        case .emptyTrash: "trash.fill"
        case .ejectDisks: "eject.fill"
        case .micMute: "mic.slash.fill"
        case .dockAutohide: "dock.rectangle"
        case .menuBarAutohide: "menubar.rectangle"
        case .showHiddenFiles: "eye.fill"
        case .trueTone: "circle.lefthalf.filled"
        case .lowPower: "battery.25percent"
        case .outputMute: "speaker.slash.fill"
        case .wifi: "wifi"
        case .bluetooth: "antenna.radiowaves.left.and.right"
        case .hideWindows: "macwindow.on.rectangle"
        case .lockScreen: "lock.fill"
        case .displaySleep: "moon.zzz.fill"
        case .clearClipboard: "doc.on.clipboard.fill"
        case .xcodeCache: "hammer.fill"
        }
    }

    var detail: String {
        switch self {
        case .hideDesktop: String(localized: "隐藏桌面上的所有文件和图标，适合录屏、演示或截图。会自动重启访达。")
        case .darkMode: String(localized: "在浅色和深色外观之间切换。首次使用需允许控制“系统事件”。")
        case .keepAwake: String(localized: "阻止显示器进入睡眠。可设置持续时间，到时自动关闭。")
        case .screenSaver: String(localized: "立即启动屏幕保护程序。")
        case .nightShift: String(localized: "开启或关闭夜览，让屏幕颜色更暖。")
        case .screenClean: String(localized: "全屏变黑并锁定键盘，方便擦拭屏幕和键盘。长按 Esc 3 秒退出。")
        case .emptyTrash: String(localized: "一键清空废纸篓。显示项目数需要给 SwitchBox“完全磁盘访问权限”。")
        case .ejectDisks: String(localized: "一键推出所有外接磁盘和磁盘映像。")
        case .micMute: String(localized: "把输入音量设为 0，再次切换时恢复之前的音量。")
        case .dockAutohide: String(localized: "自动隐藏和显示程序坞。")
        case .menuBarAutohide: String(localized: "自动隐藏和显示菜单栏。")
        case .showHiddenFiles: String(localized: "在访达中显示以“.”开头的隐藏文件。会自动重启访达。")
        case .trueTone: String(localized: "根据环境光自动调整屏幕色彩。")
        case .lowPower: String(localized: "降低能耗、延长续航。切换时需要输入管理员密码。")
        case .outputMute: String(localized: "静音或恢复系统声音输出。")
        case .wifi: String(localized: "打开或关闭 Wi‑Fi。")
        case .bluetooth: String(localized: "打开或关闭蓝牙。")
        case .hideWindows: String(localized: "一键隐藏所有其他应用的窗口，再次切换时恢复。")
        case .lockScreen: String(localized: "立即锁定屏幕。")
        case .displaySleep: String(localized: "立即让显示器进入睡眠，不影响后台任务。")
        case .clearClipboard: String(localized: "清空剪贴板内容，保护隐私。")
        case .xcodeCache: String(localized: "删除 Xcode 的 DerivedData 编译缓存，释放磁盘空间。")
        }
    }

    var shortDetail: String {
        switch self {
        case .hideDesktop: String(localized: "录屏、演示时隐藏桌面文件")
        case .darkMode: String(localized: "切换浅色 / 深色外观")
        case .keepAwake: String(localized: "阻止显示器自动睡眠")
        case .screenSaver: String(localized: "立即启动屏幕保护程序")
        case .nightShift: String(localized: "让屏幕色温更暖")
        case .screenClean: String(localized: "黑屏并锁定键盘，方便擦拭")
        case .emptyTrash: String(localized: "一键清空废纸篓")
        case .ejectDisks: String(localized: "推出所有外接磁盘")
        case .micMute: String(localized: "将麦克风输入音量设为 0")
        case .dockAutohide: String(localized: "自动隐藏和显示程序坞")
        case .menuBarAutohide: String(localized: "自动隐藏和显示菜单栏")
        case .showHiddenFiles: String(localized: "在访达中显示隐藏文件")
        case .trueTone: String(localized: "根据环境光调整屏幕色彩")
        case .lowPower: String(localized: "降低能耗，延长续航")
        case .outputMute: String(localized: "静音系统声音")
        case .wifi: String(localized: "打开或关闭 Wi‑Fi")
        case .bluetooth: String(localized: "打开或关闭蓝牙")
        case .hideWindows: String(localized: "隐藏所有其他应用窗口")
        case .lockScreen: String(localized: "立即锁定屏幕")
        case .displaySleep: String(localized: "立即关闭显示器")
        case .clearClipboard: String(localized: "清空剪贴板内容")
        case .xcodeCache: String(localized: "删除 DerivedData 释放空间")
        }
    }

    /// 一次性动作（打开后自动回弹）
    var isMomentary: Bool {
        [.screenSaver, .emptyTrash, .ejectDisks, .screenClean, .lockScreen, .displaySleep, .clearClipboard, .xcodeCache].contains(self)
    }

    var actionLabel: String {
        switch self {
        case .screenSaver, .screenClean: String(localized: "开始")
        case .emptyTrash: String(localized: "清空")
        case .ejectDisks: String(localized: "推出")
        case .lockScreen: String(localized: "锁定")
        case .displaySleep: String(localized: "休眠")
        case .clearClipboard: String(localized: "清空")
        case .xcodeCache: String(localized: "清理")
        default: ""
        }
    }

    static let defaultEnabled: Set<SwitchID> = [.hideDesktop, .darkMode, .keepAwake, .nightShift, .micMute, .screenSaver, .screenClean, .emptyTrash, .ejectDisks]
}

enum PrefsTab: Hashable { case general, customize, shortcuts, about }

@MainActor
final class SwitchStore: ObservableObject {
    static let shared = SwitchStore()

    @Published var order: [SwitchID] { didSet { save() } }
    @Published var enabled: Set<SwitchID> { didSet { save() } }
    @Published var states: [SwitchID: Bool] = [:]
    @Published var subtitles: [SwitchID: String] = [:]
    @Published var disabled: Set<SwitchID> = []
    @Published var busy: Set<SwitchID> = []
    @Published var prefsTab: PrefsTab = .general
    @Published var awakeMinutes: Int { didSet { UserDefaults.standard.set(awakeMinutes, forKey: "awakeMinutes"); refresh() } }
    @Published var shortcuts: [SwitchID: Shortcut] {
        didSet {
            if let data = try? JSONEncoder().encode(shortcuts) { UserDefaults.standard.set(data, forKey: "shortcuts") }
            HotKeyCenter.shared.register(shortcuts)
        }
    }
    @Published var darkSchedule: DarkScheduleMode {
        didSet {
            UserDefaults.standard.set(darkSchedule.rawValue, forKey: "darkSchedule")
            if darkSchedule == .sun { LocationProvider.shared.request() }
            lastDesiredDark = nil
            checkDarkSchedule()
            refresh()
        }
    }
    @Published var darkStart: Int { didSet { UserDefaults.standard.set(darkStart, forKey: "darkStart"); lastDesiredDark = nil; checkDarkSchedule(); refresh() } }
    @Published var darkEnd: Int { didSet { UserDefaults.standard.set(darkEnd, forKey: "darkEnd"); lastDesiredDark = nil; checkDarkSchedule(); refresh() } }
    @Published var nightShiftAuto = false
    @Published var ejectExcluded: [String] { didSet { UserDefaults.standard.set(ejectExcluded, forKey: "ejectExcluded"); refresh() } }
    private var lastDesiredDark: Bool?
    @Published var showHUD: Bool { didSet { UserDefaults.standard.set(showHUD, forKey: "showHUD") } }
    @Published var menuIcon: String { didSet { UserDefaults.standard.set(menuIcon, forKey: "menuIcon") } }

    let keepAwake = KeepAwake()
    let nightShift = NightShift()
    let trueTone = TrueTone()
    private var xcodeCacheSize: Int64?
    private var xcodeSizing = false
    private var xcodeCheckedAt = Date.distantPast
    let cleaner = ScreenCleaner()
    private var ticker: Timer?

    static let awakeOptions = [0, 5, 15, 30, 60, 120, 300, 480]
    static let menuIcons = [MenuBarIcon.brand, "slider.horizontal.3", "square.grid.2x2.fill", "bolt.circle.fill", "togglepower"]

    private init() {
        let d = UserDefaults.standard
        let saved = (d.stringArray(forKey: "order") ?? []).compactMap(SwitchID.init(rawValue:))
        order = saved + SwitchID.allCases.filter { !saved.contains($0) }
        if let en = d.stringArray(forKey: "enabled") {
            enabled = Set(en.compactMap(SwitchID.init(rawValue:)))
        } else {
            enabled = SwitchID.defaultEnabled
        }
        awakeMinutes = d.object(forKey: "awakeMinutes") as? Int ?? 60
        let savedIcon = d.string(forKey: "menuIcon") ?? MenuBarIcon.brand
        menuIcon = Self.menuIcons.contains(savedIcon) ? savedIcon : MenuBarIcon.brand
        showHUD = d.object(forKey: "showHUD") as? Bool ?? true
        darkSchedule = DarkScheduleMode(rawValue: d.string(forKey: "darkSchedule") ?? "") ?? .manual
        darkStart = d.object(forKey: "darkStart") as? Int ?? 22 * 60
        darkEnd = d.object(forKey: "darkEnd") as? Int ?? 7 * 60
        ejectExcluded = d.stringArray(forKey: "ejectExcluded") ?? []
        if let data = d.data(forKey: "shortcuts"),
           let map = try? JSONDecoder().decode([SwitchID: Shortcut].self, from: data) {
            shortcuts = map
        } else {
            shortcuts = [:]
        }
        HotKeyCenter.shared.register(shortcuts)
        HotKeyCenter.shared.handler = { [weak self] id in self?.trigger(id) }
        LocationProvider.shared.onUpdate = { [weak self] in
            DispatchQueue.main.async { self?.lastDesiredDark = nil; self?.checkDarkSchedule(); self?.refresh() }
        }
        if darkSchedule == .sun { LocationProvider.shared.request() }

        keepAwake.onExpire = { [weak self] in Task { @MainActor in self?.refresh() } }
        cleaner.onFinish = { [weak self] in Task { @MainActor in self?.refresh() } }
        refresh()
        ticker = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkDarkSchedule(); self?.refresh() }
        }
        checkDarkSchedule()
    }

    private func save() {
        UserDefaults.standard.set(order.map(\.rawValue), forKey: "order")
        UserDefaults.standard.set(enabled.map(\.rawValue), forKey: "enabled")
    }

    var visibleSwitches: [SwitchID] { order.filter { enabled.contains($0) } }

    var activeCount: Int { visibleSwitches.filter { !$0.isMomentary && states[$0] == true }.count }

    func resetLayout() {
        withAnimation {
            order = SwitchID.allCases
            enabled = SwitchID.defaultEnabled
        }
    }

    func refresh() {
        var s: [SwitchID: Bool] = [:]
        var sub: [SwitchID: String] = [:]
        var dis: Set<SwitchID> = []

        s[.hideDesktop] = Finder.desktopHidden
        s[.showHiddenFiles] = Finder.showsHiddenFiles
        s[.darkMode] = Appearance.isDark
        s[.dockAutohide] = Appearance.dockAutohide
        s[.menuBarAutohide] = Appearance.menuBarAutohide
        s[.keepAwake] = keepAwake.isOn

        if let end = keepAwake.endDate {
            let mins = max(1, Int(ceil(end.timeIntervalSinceNow / 60)))
            sub[.keepAwake] = String(localized: "剩余 \(Self.durationText(mins))")
        } else {
            sub[.keepAwake] = Self.durationText(awakeMinutes)
        }

        if let ds = darkScheduleSubtitle() { sub[.darkMode] = ds }
        if nightShift.isAvailable {
            nightShiftAuto = nightShift.mode == 1
            if nightShiftAuto { sub[.nightShift] = String(localized: "日落到日出自动开启") }
        }
        if nightShift.isAvailable { s[.nightShift] = nightShift.isOn } else { dis.insert(.nightShift); sub[.nightShift] = String(localized: "此 Mac 不支持") }

        if enabled.contains(.micMute) { s[.micMute] = Microphone.isMuted }
        if enabled.contains(.outputMute) { s[.outputMute] = Speaker.isMuted }

        if trueTone.isAvailable { s[.trueTone] = trueTone.isOn } else { dis.insert(.trueTone); sub[.trueTone] = String(localized: "此显示器不支持") }

        if enabled.contains(.lowPower) {
            if let lp = LowPower.state { s[.lowPower] = lp } else { dis.insert(.lowPower); sub[.lowPower] = String(localized: "此 Mac 不支持") }
        }

        if WiFi.isAvailable {
            let on = WiFi.isOn
            s[.wifi] = on
            sub[.wifi] = on ? (WiFi.ssid ?? String(localized: "已开启")) : String(localized: "已关闭")
        } else { dis.insert(.wifi); sub[.wifi] = String(localized: "未找到 Wi‑Fi 硬件") }

        if Bluetooth.isAvailable { s[.bluetooth] = Bluetooth.isOn } else { dis.insert(.bluetooth); sub[.bluetooth] = String(localized: "不可用") }

        s[.hideWindows] = WindowHider.isOn

        if enabled.contains(.xcodeCache) {
            if let size = xcodeCacheSize {
                sub[.xcodeCache] = size == 0 ? String(localized: "没有可清理的缓存") : String(localized: "可释放 \(XcodeCache.format(size))")
                if size == 0 { dis.insert(.xcodeCache) }
            } else {
                sub[.xcodeCache] = String(localized: "正在计算…")
            }
            updateXcodeCacheSize()
        }

        if let n = Trash.itemCount {
            sub[.emptyTrash] = n == 0 ? String(localized: "废纸篓是空的") : String(localized: "\(n) 个项目")
            if n == 0 { dis.insert(.emptyTrash) }
        }
        let disks = Disks.ejectable(excluding: ejectExcluded).count
        sub[.ejectDisks] = disks == 0 ? String(localized: "未连接外接磁盘") : String(localized: "\(disks) 个磁盘可推出")
        if disks == 0 { dis.insert(.ejectDisks) }

        states = s; subtitles = sub; disabled = dis
    }

    // MARK: 深色模式计划

    var sunTimes: (sunrise: Date, sunset: Date)? {
        let c = LocationProvider.shared.coordinate
        return Solar.sunTimes(latitude: c.lat, longitude: c.lon)
    }

    /// 当前时间按计划应该是深色吗？手动模式返回 nil
    private func desiredDark(at now: Date = Date()) -> Bool? {
        switch darkSchedule {
        case .manual: return nil
        case .sun:
            guard let t = sunTimes else { return nil }
            return now < t.sunrise || now >= t.sunset
        case .custom:
            let c = Calendar.current.dateComponents([.hour, .minute], from: now)
            let m = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            if darkStart == darkEnd { return nil }
            return darkStart < darkEnd ? (m >= darkStart && m < darkEnd) : (m >= darkStart || m < darkEnd)
        }
    }

    /// 只在计划的切换点生效，手动切换会保持到下一个切换点
    func checkDarkSchedule() {
        guard let desired = desiredDark() else { return }
        if desired != lastDesiredDark {
            lastDesiredDark = desired
            if Appearance.isDark != desired { Appearance.setDark(desired) }
        }
    }

    private func darkScheduleSubtitle() -> String? {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        switch darkSchedule {
        case .manual: return nil
        case .sun:
            guard let t = sunTimes else { return String(localized: "日出日落 · 无法计算") }
            return Appearance.isDark ? String(localized: "日出 \(f.string(from: t.sunrise)) 关闭") : String(localized: "日落 \(f.string(from: t.sunset)) 开启")
        case .custom:
            return String(localized: "\(formatMinutes(darkStart)) – \(formatMinutes(darkEnd)) 自动")
        }
    }

    func toggleEjectExcluded(_ path: String) {
        if let i = ejectExcluded.firstIndex(of: path) { ejectExcluded.remove(at: i) } else { ejectExcluded.append(path) }
    }

    func setNightShiftAuto(_ on: Bool) {
        nightShift.setMode(on ? 1 : 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.refresh() }
    }

    private func updateXcodeCacheSize(force: Bool = false) {
        guard !xcodeSizing, force || Date().timeIntervalSince(xcodeCheckedAt) > 60 else { return }
        xcodeSizing = true
        DispatchQueue.global(qos: .utility).async {
            let size = XcodeCache.size()
            DispatchQueue.main.async {
                self.xcodeCacheSize = size
                self.xcodeSizing = false
                self.xcodeCheckedAt = Date()
                self.refresh()
            }
        }
    }

    static func durationText(_ minutes: Int) -> String {
        switch minutes {
        case 0: String(localized: "永久")
        case ..<60: String(localized: "\(minutes) 分钟")
        default: minutes % 60 == 0 ? String(localized: "\(minutes / 60) 小时") : String(localized: "\(minutes / 60) 小时 \(minutes % 60) 分钟")
        }
    }

    func binding(_ id: SwitchID) -> Binding<Bool> {
        Binding(get: { self.states[id] ?? false }, set: { self.set(id, $0) })
    }

    func set(_ id: SwitchID, _ on: Bool) {
        states[id] = on
        switch id {
        case .hideDesktop: Finder.setDesktopHidden(on)
        case .showHiddenFiles: Finder.setShowsHiddenFiles(on)
        case .darkMode: Appearance.setDark(on)
        case .dockAutohide: Appearance.setDockAutohide(on)
        case .menuBarAutohide: Appearance.setMenuBarAutohide(on)
        case .keepAwake: on ? keepAwake.start(minutes: awakeMinutes) : keepAwake.stop()
        case .nightShift: nightShift.set(on)
        case .micMute: Microphone.setMuted(on)
        case .outputMute: Speaker.setMuted(on)
        case .trueTone: trueTone.set(on)
        case .lowPower: DispatchQueue.main.async { LowPower.set(on); self.refresh() }
        case .wifi: WiFi.set(on)
        case .bluetooth: Bluetooth.set(on)
        case .hideWindows: WindowHider.set(on)
        case .screenClean, .screenSaver, .emptyTrash, .ejectDisks, .lockScreen, .displaySleep, .clearClipboard, .xcodeCache:
            perform(id)
        }
        if !id.isMomentary {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.refresh() }
        }
    }

    /// 从菜单里选择时长：立即以该时长开启
    func startKeepAwake(minutes: Int) {
        awakeMinutes = minutes
        set(.keepAwake, true)
    }

    /// 快捷键触发
    func trigger(_ id: SwitchID) {
        refresh()
        if disabled.contains(id) {
            if showHUD { HUD.shared.show(id: id, message: subtitles[id] ?? String(localized: "当前不可用"), active: false) }
            NSSound.beep()
            return
        }
        if id.isMomentary {
            if showHUD && ![.screenClean, .screenSaver, .lockScreen, .displaySleep, .clearClipboard, .xcodeCache].contains(id) {
                HUD.shared.show(id: id, message: String(localized: "已执行"), active: true)
            }
            perform(id)
        } else {
            let on = !(states[id] ?? false)
            set(id, on)
            if showHUD { HUD.shared.show(id: id, message: on ? String(localized: "已开启") : String(localized: "已关闭"), active: on) }
        }
    }

    func setShortcut(_ sc: Shortcut?, for id: SwitchID) {
        if let sc {
            // 同一组合只能分配给一个开关
            for (k, v) in shortcuts where v.keyCode == sc.keyCode && v.carbonModifiers == sc.carbonModifiers { shortcuts[k] = nil }
            shortcuts[id] = sc
        } else {
            shortcuts[id] = nil
        }
    }

    /// 一次性动作
    func perform(_ id: SwitchID) {
        switch id {
        case .screenClean:
            closeMenu()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self.cleaner.start() }
        case .screenSaver:
            closeMenu()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { ScreenSaver.start() }
        case .emptyTrash:
            busy.insert(id)
            DispatchQueue.main.async {
                Trash.empty()
                self.busy.remove(id); self.refresh()
            }
        case .ejectDisks:
            busy.insert(id)
            Disks.ejectAll(excluding: ejectExcluded) { _ in self.busy.remove(id); self.refresh() }
        case .lockScreen:
            closeMenu()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { ScreenLock.lock() }
        case .displaySleep:
            closeMenu()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { ScreenLock.sleepDisplay() }
        case .clearClipboard:
            Clipboard.clear()
            if showHUD { HUD.shared.show(id: id, message: String(localized: "剪贴板已清空"), active: true) }
        case .xcodeCache:
            busy.insert(id)
            let freed = xcodeCacheSize ?? 0
            DispatchQueue.global(qos: .utility).async {
                XcodeCache.clean()
                DispatchQueue.main.async {
                    self.busy.remove(id)
                    self.xcodeCacheSize = nil
                    self.updateXcodeCacheSize(force: true)
                    if self.showHUD { HUD.shared.show(id: id, message: String(localized: "已释放 \(XcodeCache.format(freed))"), active: true) }
                }
            }
        default: break
        }
    }

    /// 收起菜单栏弹窗
    private func closeMenu() {
        for w in NSApp.windows where w.className.contains("MenuBarExtraWindow") { w.orderOut(nil) }
    }

    // MARK: 登录时启动
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do { newValue ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
            catch { NSLog("[SwitchBox] login item error: \(error)") }
            objectWillChange.send()
        }
    }
}

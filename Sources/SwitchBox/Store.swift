import SwiftUI
import ServiceManagement

enum SwitchID: String, CaseIterable, Identifiable, Codable {
    case hideDesktop, darkMode, keepAwake, screenSaver, nightShift, screenClean,
         emptyTrash, ejectDisks, micMute, dockAutohide, menuBarAutohide, showHiddenFiles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hideDesktop: "隐藏桌面图标"
        case .darkMode: "深色模式"
        case .keepAwake: "保持亮屏"
        case .screenSaver: "屏幕保护"
        case .nightShift: "夜览"
        case .screenClean: "屏幕清洁"
        case .emptyTrash: "清空废纸篓"
        case .ejectDisks: "推出磁盘"
        case .micMute: "麦克风静音"
        case .dockAutohide: "自动隐藏程序坞"
        case .menuBarAutohide: "自动隐藏菜单栏"
        case .showHiddenFiles: "显示隐藏文件"
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
        }
    }

    var detail: String {
        switch self {
        case .hideDesktop: "隐藏桌面上的所有文件和图标，适合录屏、演示或截图。会自动重启访达。"
        case .darkMode: "在浅色和深色外观之间切换。首次使用需允许控制“系统事件”。"
        case .keepAwake: "阻止显示器进入睡眠。可设置持续时间，到时自动关闭。"
        case .screenSaver: "立即启动屏幕保护程序。"
        case .nightShift: "开启或关闭夜览，让屏幕颜色更暖。"
        case .screenClean: "全屏变黑并锁定键盘，方便擦拭屏幕和键盘。长按 Esc 3 秒退出。"
        case .emptyTrash: "一键清空废纸篓。显示项目数需要给 SwitchBox“完全磁盘访问权限”。"
        case .ejectDisks: "一键推出所有外接磁盘和磁盘映像。"
        case .micMute: "把输入音量设为 0，再次切换时恢复之前的音量。"
        case .dockAutohide: "自动隐藏和显示程序坞。"
        case .menuBarAutohide: "自动隐藏和显示菜单栏。"
        case .showHiddenFiles: "在访达中显示以“.”开头的隐藏文件。会自动重启访达。"
        }
    }

    var shortDetail: String {
        switch self {
        case .hideDesktop: "录屏、演示时隐藏桌面文件"
        case .darkMode: "切换浅色 / 深色外观"
        case .keepAwake: "阻止显示器自动睡眠"
        case .screenSaver: "立即启动屏幕保护程序"
        case .nightShift: "让屏幕色温更暖"
        case .screenClean: "黑屏并锁定键盘，方便擦拭"
        case .emptyTrash: "一键清空废纸篓"
        case .ejectDisks: "推出所有外接磁盘"
        case .micMute: "将麦克风输入音量设为 0"
        case .dockAutohide: "自动隐藏和显示程序坞"
        case .menuBarAutohide: "自动隐藏和显示菜单栏"
        case .showHiddenFiles: "在访达中显示隐藏文件"
        }
    }

    /// 一次性动作（打开后自动回弹）
    var isMomentary: Bool { [.screenSaver, .emptyTrash, .ejectDisks, .screenClean].contains(self) }

    var actionLabel: String {
        switch self {
        case .screenSaver, .screenClean: "开始"
        case .emptyTrash: "清空"
        case .ejectDisks: "推出"
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
    @Published var showHUD: Bool { didSet { UserDefaults.standard.set(showHUD, forKey: "showHUD") } }
    @Published var menuIcon: String { didSet { UserDefaults.standard.set(menuIcon, forKey: "menuIcon") } }

    let keepAwake = KeepAwake()
    let nightShift = NightShift()
    let cleaner = ScreenCleaner()
    private var ticker: Timer?

    static let awakeOptions = [0, 5, 15, 30, 60, 120, 300, 480]
    static let menuIcons = ["switch.2", "slider.horizontal.3", "square.grid.2x2.fill", "bolt.circle.fill", "togglepower"]

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
        menuIcon = d.string(forKey: "menuIcon") ?? "switch.2"
        showHUD = d.object(forKey: "showHUD") as? Bool ?? true
        if let data = d.data(forKey: "shortcuts"),
           let map = try? JSONDecoder().decode([SwitchID: Shortcut].self, from: data) {
            shortcuts = map
        } else {
            shortcuts = [:]
        }
        HotKeyCenter.shared.register(shortcuts)
        HotKeyCenter.shared.handler = { [weak self] id in self?.trigger(id) }

        keepAwake.onExpire = { [weak self] in Task { @MainActor in self?.refresh() } }
        cleaner.onFinish = { [weak self] in Task { @MainActor in self?.refresh() } }
        refresh()
        ticker = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
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
            sub[.keepAwake] = "剩余 \(Self.durationText(mins))"
        } else {
            sub[.keepAwake] = Self.durationText(awakeMinutes)
        }

        if nightShift.isAvailable { s[.nightShift] = nightShift.isOn } else { dis.insert(.nightShift); sub[.nightShift] = "此 Mac 不支持" }

        if enabled.contains(.micMute) { s[.micMute] = Microphone.isMuted }

        if let n = Trash.itemCount {
            sub[.emptyTrash] = n == 0 ? "废纸篓是空的" : "\(n) 个项目"
            if n == 0 { dis.insert(.emptyTrash) }
        }
        let disks = Disks.ejectable.count
        sub[.ejectDisks] = disks == 0 ? "未连接外接磁盘" : "\(disks) 个磁盘可推出"
        if disks == 0 { dis.insert(.ejectDisks) }

        states = s; subtitles = sub; disabled = dis
    }

    static func durationText(_ minutes: Int) -> String {
        switch minutes {
        case 0: "永久"
        case ..<60: "\(minutes) 分钟"
        default: minutes % 60 == 0 ? "\(minutes / 60) 小时" : "\(minutes / 60) 小时 \(minutes % 60) 分钟"
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
        case .screenClean, .screenSaver, .emptyTrash, .ejectDisks:
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
            if showHUD { HUD.shared.show(id: id, message: subtitles[id] ?? "当前不可用", active: false) }
            NSSound.beep()
            return
        }
        if id.isMomentary {
            if showHUD && id != .screenClean && id != .screenSaver {
                HUD.shared.show(id: id, message: "已执行", active: true)
            }
            perform(id)
        } else {
            let on = !(states[id] ?? false)
            set(id, on)
            if showHUD { HUD.shared.show(id: id, message: on ? "已开启" : "已关闭", active: on) }
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
            Disks.ejectAll { _ in self.busy.remove(id); self.refresh() }
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

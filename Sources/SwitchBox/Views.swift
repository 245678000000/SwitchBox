import SwiftUI

// MARK: - 菜单栏面板

struct MenuPanel: View {
    @ObservedObject var store: SwitchStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        let items = store.visibleSwitches
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)

            VStack(spacing: 2) {
                if items.isEmpty {
                    emptyState
                } else {
                    ForEach(items) { SwitchRow(id: $0, store: store) }
                }
            }
            .padding(6)

            Divider().opacity(0.5)
            footer
        }
        .frame(width: 320)
        .onAppear { store.refresh() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("SwitchBox")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            let n = store.activeCount
            (n == 0 ? Text("全部关闭") : Text("\(n) 项已开启"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(n == 0 ? AnyShapeStyle(.tertiary) : AnyShapeStyle(Color.accentColor))
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(Capsule().fill(n == 0 ? Color.primary.opacity(0.05) : Color.accentColor.opacity(0.12)))
                .contentTransition(.numericText())
                .animation(.snappy, value: n)
        }
        .padding(.horizontal, 16)
        .frame(height: 42)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.dashed").font(.system(size: 26, weight: .light)).foregroundStyle(.tertiary)
            Text("还没有启用任何开关").font(.system(size: 12)).foregroundStyle(.secondary)
            Button("添加开关") { openPrefs(.customize) }.buttonStyle(PillButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }

    private var footer: some View {
        HStack {
            HoverIconButton(symbol: "gearshape", help: "设置") { openPrefs(.general) }
            Spacer()
            Button { openPrefs(.customize) } label: {
                Label("自定义开关", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(PillButtonStyle())
            Spacer()
            HoverIconButton(symbol: "power", help: "退出 SwitchBox") { NSApp.terminate(nil) }
        }
        .padding(.horizontal, 10)
        .frame(height: 46)
    }

    private func openPrefs(_ tab: PrefsTab) {
        openPreferences(tab, store: store, openSettings: openSettings)
    }
}

@MainActor
func openPreferences(_ tab: PrefsTab, store: SwitchStore, openSettings: OpenSettingsAction) {
    store.prefsTab = tab
    NSApp.activate(ignoringOtherApps: true)
    openSettings()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first { $0.identifier?.rawValue.contains("Settings") == true }?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - 单行

struct SwitchRow: View {
    let id: SwitchID
    @ObservedObject var store: SwitchStore
    @State private var hovering = false
    @State var expanded = false
    @Environment(\.openSettings) private var openSettings

    private var isOn: Bool { store.states[id] ?? false }
    private var isDisabled: Bool { store.disabled.contains(id) }
    private var isBusy: Bool { store.busy.contains(id) }
    private var hasOptions: Bool { [.keepAwake, .darkMode, .nightShift, .ejectDisks].contains(id) }

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if expanded && hasOptions {
                optionsList
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(expanded ? 0.05 : 0))
        )
        .clipped()
    }

    private var mainRow: some View {
        HStack(spacing: 11) {
            SwitchIcon(id: id, size: 28, active: id.isMomentary ? !isDisabled : isOn)
            VStack(alignment: .leading, spacing: 1) {
                Text(id.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if let sub = store.subtitles[id] {
                    Text(sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            Spacer(minLength: 8)
            if hasOptions { expandButton }
            trailing
        }
        .padding(.horizontal, 10)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(hovering && !isDisabled && !expanded ? 0.06 : 0))
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { activate() }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var expandButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) { expanded.toggle() }
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(expanded ? Color.accentColor : .secondary)
                .rotationEffect(.degrees(expanded ? 180 : 0))
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(expanded ? Color.accentColor.opacity(0.14) : Color.primary.opacity(hovering ? 0.08 : 0.05))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("更多选项")
    }

    private var optionsList: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 10).opacity(0.6)
            VStack(spacing: 1) {
                switch id {
                case .keepAwake: keepAwakeOptions
                case .darkMode: darkModeOptions
                case .nightShift: nightShiftOptions
                case .ejectDisks: ejectOptions
                default: EmptyView()
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
        }
    }

    private func collapse() { withAnimation(.snappy(duration: 0.25)) { expanded = false } }

    private func settingsOption(_ tab: PrefsTab, _ title: String) -> some View {
        Group {
            Divider().padding(.horizontal, 8).padding(.vertical, 3).opacity(0.6)
            OptionRow(title: title, selected: false) {
                collapse()
                openPreferences(tab, store: store, openSettings: openSettings)
            }
        }
    }

    @ViewBuilder private var keepAwakeOptions: some View {
        ForEach(SwitchStore.awakeOptions, id: \.self) { m in
            OptionRow(title: SwitchStore.durationText(m), selected: m == store.awakeMinutes,
                      badge: isOn && m == store.awakeMinutes ? "进行中" : nil) {
                store.startKeepAwake(minutes: m)
                collapse()
            }
        }
    }

    @ViewBuilder private var darkModeOptions: some View {
        OptionRow(title: "手动开关", selected: store.darkSchedule == .manual) {
            store.darkSchedule = .manual; collapse()
        }
        OptionRow(title: "根据日出日落自动开关", selected: store.darkSchedule == .sun) {
            store.darkSchedule = .sun; collapse()
        }
        OptionRow(title: String(localized: "从 \(formatMinutes(store.darkStart)) 至 \(formatMinutes(store.darkEnd))"),
                  selected: store.darkSchedule == .custom) {
            store.darkSchedule = .custom; collapse()
        }
        settingsOption(.general, "设置…")
    }

    @ViewBuilder private var nightShiftOptions: some View {
        OptionRow(title: "手动开关", selected: !store.nightShiftAuto) {
            store.setNightShiftAuto(false); collapse()
        }
        OptionRow(title: "根据日出日落自动开关", selected: store.nightShiftAuto) {
            store.setNightShiftAuto(true); collapse()
        }
    }

    @ViewBuilder private var ejectOptions: some View {
        let vols = Disks.all
        if vols.isEmpty {
            Text("未连接外接磁盘")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 45)
                .frame(height: 26)
        } else {
            ForEach(vols, id: \.path) { v in
                let excluded = store.ejectExcluded.contains(v.path)
                OptionRow(title: v.lastPathComponent, selected: !excluded, badge: excluded ? "已排除" : nil) {
                    store.toggleEjectExcluded(v.path)
                }
            }
        }
        settingsOption(.general, "设置排除项目…")
    }

    @ViewBuilder private var trailing: some View {
        if id.isMomentary {
            if isBusy {
                ProgressView().controlSize(.small).frame(width: 52)
            } else {
                Button(id.actionLabel) { activate() }
                    .buttonStyle(PillButtonStyle())
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.45 : 1)
            }
        } else {
            Toggle("", isOn: store.binding(id))
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
                .disabled(isDisabled)
        }
    }

    private func activate() {
        guard !isDisabled, !isBusy else { return }
        if id.isMomentary { store.perform(id) } else { store.set(id, !isOn) }
    }
}

struct OptionRow: View {
    let title: String
    let selected: Bool
    var badge: String? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(hovering ? Color.white : Color.accentColor)
                    .opacity(selected ? 1 : 0)
                    .frame(width: 35, alignment: .trailing)
                    .padding(.trailing, 10)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 12.5, weight: selected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer()
                if let badge {
                    Text(LocalizedStringKey(badge))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(hovering ? Color.white : Color.accentColor)
                        .padding(.horizontal, 6).frame(height: 16)
                        .background(Capsule().fill(hovering ? Color.white.opacity(0.22) : Color.accentColor.opacity(0.14)))
                        .padding(.trailing, 10)
                }
            }
            .frame(height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hovering ? Color.accentColor : .clear)
            )
            .foregroundStyle(hovering ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

// MARK: - 设置窗口

struct PrefsView: View {
    @ObservedObject var store: SwitchStore

    var body: some View {
        TabView(selection: $store.prefsTab) {
            GeneralTab(store: store)
                .tabItem { Label("通用", systemImage: "gearshape") }.tag(PrefsTab.general)
            CustomizeTab(store: store)
                .tabItem { Label("自定义", systemImage: "slider.horizontal.3") }.tag(PrefsTab.customize)
            ShortcutsTab(store: store)
                .tabItem { Label("快捷键", systemImage: "command") }.tag(PrefsTab.shortcuts)
            AboutTab()
                .tabItem { Label("关于", systemImage: "info.circle") }.tag(PrefsTab.about)
        }
    }
}

// MARK: - 设置页通用组件

/// 系统设置风格的小图标
struct SettingIcon: View {
    let symbol: String
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(colors: [color.opacity(0.85), color], startPoint: .top, endPoint: .bottom))
            .frame(width: 24, height: 24)
            .overlay(Image(systemName: symbol).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white))
    }
}

struct SettingLabel: View {
    let symbol: String
    let color: Color
    let title: String
    var subtitle: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            SettingIcon(symbol: symbol, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                if let subtitle { Text(LocalizedStringKey(subtitle)).font(.system(size: 11)).foregroundStyle(.secondary) }
            }
        }
    }
}

struct StatusBadge: View {
    let status: PermissionStatus
    var body: some View {
        let (text, icon, color): (String, String, Color) = switch status {
        case .granted: ("已授权", "checkmark.circle.fill", .green)
        case .denied: ("已拒绝", "xmark.circle.fill", .red)
        case .notDetermined: ("未授权", "exclamationmark.circle.fill", .orange)
        case .unknown: ("检测中", "circle.dotted", .secondary)
        }
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(LocalizedStringKey(text))
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Capsule().fill(color.opacity(0.12)))
    }
}

// MARK: - 通用

struct GeneralTab: View {
    @ObservedObject var store: SwitchStore
    @State private var sysEvents: PermissionStatus = .unknown
    @State private var finder: PermissionStatus = .unknown
    @State private var disk: PermissionStatus = .unknown
    @State private var language = AppLanguage.current
    @State private var languageChanged = false
    @State private var checking = false
    @State private var updateResult: UpdateResult?

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(get: { store.launchAtLogin }, set: { store.launchAtLogin = $0 })) {
                    SettingLabel(symbol: "power", color: .green, title: "登录时启动", subtitle: "开机后自动出现在菜单栏")
                }
                Picker(selection: $language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                } label: {
                    SettingLabel(symbol: "globe", color: .cyan, title: "语言", subtitle: "选择界面显示的语言")
                }
                .onChange(of: language) { _, new in
                    AppLanguage.apply(new)
                    languageChanged = true
                }
                if languageChanged {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(Color.accentColor)
                        Text("重新启动 SwitchBox 后生效").font(.system(size: 12))
                        Spacer()
                        Button("立即重启") { AppLanguage.relaunch() }
                            .buttonStyle(.borderedProminent).controlSize(.small)
                    }
                }
                LabeledContent {
                    Picker("", selection: $store.menuIcon) {
                        ForEach(SwitchStore.menuIcons, id: \.self) { Image(systemName: $0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                } label: {
                    SettingLabel(symbol: "menubar.rectangle", color: .blue, title: "菜单栏图标")
                }
                Picker(selection: $store.awakeMinutes) {
                    ForEach(SwitchStore.awakeOptions, id: \.self) { Text(SwitchStore.durationText($0)).tag($0) }
                } label: {
                    SettingLabel(symbol: "cup.and.saucer.fill", color: .orange, title: "保持亮屏时长")
                }
            }

            darkModeSection
            ejectSection
            permissionSection
            supportSection
        }
        .formStyle(.grouped)
        .frame(width: 580, height: 640)
        .onAppear { refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
        }
    }

    // MARK: 深色模式

    private var darkModeSection: some View {
        Section("深色模式") {
            Picker(selection: $store.darkSchedule) {
                ForEach(DarkScheduleMode.allCases) { Text($0.title).tag($0) }
            } label: {
                SettingLabel(symbol: "moon.stars.fill", color: .indigo, title: "自动切换")
            }
            if store.darkSchedule == .custom {
                DatePicker("开启深色模式", selection: minutesBinding(\.darkStart), displayedComponents: .hourAndMinute)
                DatePicker("恢复浅色模式", selection: minutesBinding(\.darkEnd), displayedComponents: .hourAndMinute)
            }
            if store.darkSchedule == .sun {
                let loc = LocationProvider.shared.coordinate
                LabeledContent("今日日出 / 日落") {
                    if let t = store.sunTimes {
                        Text("\(t.sunrise.formatted(date: .omitted, time: .shortened)) / \(t.sunset.formatted(date: .omitted, time: .shortened))")
                            .monospacedDigit()
                    } else {
                        Text("无法计算").foregroundStyle(.secondary)
                    }
                }
                LabeledContent {
                    Button("使用当前位置") { LocationProvider.shared.request() }.controlSize(.small)
                } label: {
                    Text("位置")
                    if loc.precise { Text("已使用你的大致位置") } else { Text("按时区估算，授权定位后更准确") }
                }
            }
        }
    }

    private func minutesBinding(_ kp: ReferenceWritableKeyPath<SwitchStore, Int>) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: store[keyPath: kp] / 60, minute: store[keyPath: kp] % 60, second: 0, of: Date()) ?? Date() },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                store[keyPath: kp] = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            })
    }

    // MARK: 推出磁盘

    private var ejectSection: some View {
        Section {
            if store.ejectExcluded.isEmpty {
                Text("没有排除的磁盘，“推出磁盘”会推出所有外接磁盘。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            ForEach(store.ejectExcluded, id: \.self) { path in
                LabeledContent {
                    Button { store.toggleEjectExcluded(path) } label: {
                        Image(systemName: "minus.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.plain)
                    .help("取消排除")
                } label: {
                    HStack(spacing: 10) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                            .resizable().frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                            Text(path).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            HStack {
                Menu {
                    let candidates = Disks.all.filter { !store.ejectExcluded.contains($0.path) }
                    if candidates.isEmpty {
                        Text("没有可添加的已连接磁盘")
                    }
                    ForEach(candidates, id: \.path) { v in
                        Button(v.lastPathComponent) { store.toggleEjectExcluded(v.path) }
                    }
                    Divider()
                    Button("选择…") { pickVolume() }
                } label: {
                    Label("添加排除项目", systemImage: "plus")
                }
                .fixedSize()
                Spacer()
            }
        } header: {
            Text("推出磁盘时排除")
        }
    }

    private func pickVolume() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = URL(fileURLWithPath: "/Volumes")
        panel.prompt = String(localized: "排除")
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url, !store.ejectExcluded.contains(url.path) {
            store.ejectExcluded.append(url.path)
        }
    }

    // MARK: 权限

    private var permissionSection: some View {
        Section {
            permissionRow(symbol: "gearshape.2.fill", color: .gray, title: "系统事件",
                          subtitle: "切换深色模式、程序坞、菜单栏", status: sysEvents) {
                request("com.apple.systemevents") { sysEvents = $0 }
            }
            permissionRow(symbol: "face.smiling.inverse", color: .blue, title: "访达",
                          subtitle: "清空废纸篓", status: finder) {
                request("com.apple.finder") { finder = $0 }
            }
            permissionRow(symbol: "internaldrive.fill", color: .indigo, title: "完全磁盘访问权限",
                          subtitle: "显示废纸篓里的项目数量（可选）", status: disk) {
                Permissions.openFullDiskSettings()
            }
        } header: {
            HStack {
                Text("权限")
                Spacer()
                Button { refreshPermissions() } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless)
                    .help("重新检测")
            }
        } footer: {
            Text("点“授权”会弹出系统对话框，选“允许”即可。如果之前点过“不允许”，请点“去设置”，在“自动化”里找到 SwitchBox 并打开对应开关。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: 更新与支持

    private var supportSection: some View {
        Section("更新与支持") {
            LabeledContent {
                HStack(spacing: 10) {
                    switch updateResult {
                    case .upToDate:
                        Label("已是最新版本", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12)).foregroundStyle(.green)
                    case .available(let v, let url):
                        Button("下载 \(v)") { NSWorkspace.shared.open(url) }
                            .buttonStyle(.borderedProminent).controlSize(.small)
                    case .failed:
                        Label("检查失败", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12)).foregroundStyle(.orange)
                    case nil: EmptyView()
                    }
                    if checking { ProgressView().controlSize(.small) }
                    Button("检查更新") {
                        checking = true
                        updateResult = nil
                        Updater.check { r in checking = false; updateResult = r }
                    }
                    .disabled(checking)
                }
            } label: {
                SettingLabel(symbol: "arrow.down.circle.fill", color: .blue, title: "更新",
                             subtitle: String(localized: "当前版本：\(AppInfo.version) (\(AppInfo.build))"))
            }
            LabeledContent {
                Button("发送反馈") { AppInfo.sendFeedback() }
            } label: {
                SettingLabel(symbol: "bubble.left.and.bubble.right.fill", color: .green, title: "支持",
                             subtitle: "报告问题或提出建议")
            }
            LabeledContent {
                Link("GitHub", destination: AppInfo.homepage)
            } label: {
                SettingLabel(symbol: "chevron.left.forwardslash.chevron.right", color: .gray, title: "项目主页",
                             subtitle: "开源代码与更新日志")
            }
            LabeledContent {
                Button("退出 SwitchBox") { NSApp.terminate(nil) }
            } label: {
                SettingLabel(symbol: "xmark.circle.fill", color: .red, title: "退出")
            }
        }
    }

    private func permissionRow(symbol: String, color: Color, title: String, subtitle: String,
                               status: PermissionStatus, action: @escaping () -> Void) -> some View {
        LabeledContent {
            HStack(spacing: 10) {
                StatusBadge(status: status)
                switch status {
                case .granted: EmptyView()
                case .notDetermined: Button("授权", action: action).buttonStyle(.borderedProminent).controlSize(.small)
                case .denied, .unknown:
                    Button("去设置") {
                        if title.contains("磁盘") { Permissions.openFullDiskSettings() } else { Permissions.openAutomationSettings() }
                    }
                    .controlSize(.small)
                }
            }
        } label: {
            SettingLabel(symbol: symbol, color: color, title: title, subtitle: subtitle)
        }
    }

    private func refreshPermissions() {
        disk = Permissions.fullDiskAccess
        DispatchQueue.global().async {
            let a = Permissions.automation("com.apple.systemevents", ask: false)
            let b = Permissions.automation("com.apple.finder", ask: false)
            DispatchQueue.main.async { sysEvents = a; finder = b }
        }
    }

    private func request(_ bundleID: String, update: @escaping (PermissionStatus) -> Void) {
        DispatchQueue.global().async {
            let r = Permissions.automation(bundleID, ask: true)
            DispatchQueue.main.async { update(r) }
        }
    }
}

// MARK: - 自定义

struct CustomizeTab: View {
    @ObservedObject var store: SwitchStore

    private var shown: [SwitchID] { store.order.filter { store.enabled.contains($0) } }
    private var hidden: [SwitchID] { store.order.filter { !store.enabled.contains($0) } }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("菜单栏开关").font(.system(size: 15, weight: .semibold))
                    Text("拖动调整顺序，点 ⊕ / ⊖ 添加或移除").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Button("恢复默认") { store.resetLayout() }.controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 6)

            List {
                Section {
                    ForEach(shown) { id in
                        CustomizeRow(id: id, included: true, store: store) {
                            withAnimation(.snappy) { _ = store.enabled.remove(id) }
                        }
                    }
                    .onMove(perform: moveShown)
                } header: {
                    sectionHeader("已显示", count: shown.count)
                }

                if !hidden.isEmpty {
                    Section {
                        ForEach(hidden) { id in
                            CustomizeRow(id: id, included: false, store: store) {
                                withAnimation(.snappy) { addToEnd(id) }
                            }
                        }
                    } header: {
                        sectionHeader("更多开关", count: hidden.count)
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 50)
        }
        .frame(width: 580, height: 560)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(LocalizedStringKey(title)).font(.system(size: 12, weight: .semibold))
            Text("\(count)").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
        }
        .padding(.top, 6)
    }

    private func moveShown(from src: IndexSet, to dst: Int) {
        var list = shown
        list.move(fromOffsets: src, toOffset: dst)
        store.order = list + hidden
    }

    private func addToEnd(_ id: SwitchID) {
        store.order = shown + [id] + hidden.filter { $0 != id }
        store.enabled.insert(id)
    }
}

struct CustomizeRow: View {
    let id: SwitchID
    let included: Bool
    @ObservedObject var store: SwitchStore
    let toggle: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Image(systemName: included ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 17))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, included ? Color.red : Color.green)
            }
            .buttonStyle(.plain)
            .help(included ? "从菜单移除" : "添加到菜单")

            SwitchIcon(id: id, size: 30, active: included)

            VStack(alignment: .leading, spacing: 2) {
                Text(id.title).font(.system(size: 13, weight: .medium))
                Text(id.shortDetail).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer(minLength: 8)

            if id == .keepAwake && included {
                Picker("", selection: $store.awakeMinutes) {
                    ForEach(SwitchStore.awakeOptions, id: \.self) { Text(SwitchStore.durationText($0)).tag($0) }
                }
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
            }

            if included {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(hovering ? .secondary : .tertiary)
                    .help("拖动排序")
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}

// MARK: - 快捷键

struct ShortcutsTab: View {
    @ObservedObject var store: SwitchStore

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $store.showHUD) {
                    SettingLabel(symbol: "rectangle.inset.filled.on.rectangle", color: .purple,
                                 title: "显示切换提示", subtitle: "用快捷键切换时，在屏幕上显示状态浮窗")
                }
            }
            Section {
                ForEach(store.order) { id in
                    LabeledContent {
                        ShortcutRecorder(shortcut: store.shortcuts[id]) { store.setShortcut($0, for: id) }
                    } label: {
                        HStack(spacing: 10) {
                            SwitchIcon(id: id, size: 24, active: true)
                            Text(id.title)
                        }
                    }
                }
            } header: {
                Text("全局快捷键")
            } footer: {
                Text("点击右侧方框后按下组合键，需包含 ⌘、⌥ 或 ⌃ 之一（F1–F12 可单独使用）。按 esc 取消，按 ⌫ 清除。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 580, height: 600)
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 0) {
            AppIconView(size: 112)
            Text("SwitchBox")
                .font(.system(size: 22, weight: .bold))
                .padding(.top, 8)
            Text("版本 \(AppInfo.version)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            Text("把常用的系统开关收进菜单栏，一键切换。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.top, 14)

            HStack(spacing: 22) {
                stat("\(SwitchID.allCases.count)", "个开关")
                Divider().frame(height: 26)
                stat("原生", "SwiftUI")
                Divider().frame(height: 26)
                stat("0", "数据收集")
            }
            .padding(.top, 26)

            Spacer()
            Text("© 2026 SwitchBox")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 18)
        }
        .padding(.top, 34)
        .frame(width: 580, height: 420)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(LocalizedStringKey(value)).font(.system(size: 15, weight: .semibold))
            Text(LocalizedStringKey(label)).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }
}

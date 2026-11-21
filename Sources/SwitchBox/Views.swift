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
        .frame(width: 300)
        .onAppear { store.refresh() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("SwitchBox")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            let n = store.activeCount
            Text(n == 0 ? "全部关闭" : "\(n) 项已开启")
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
        store.prefsTab = tab
        NSApp.activate(ignoringOtherApps: true)
        openSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first { $0.identifier?.rawValue.contains("Settings") == true }?.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - 单行

struct SwitchRow: View {
    let id: SwitchID
    @ObservedObject var store: SwitchStore
    @State private var hovering = false
    @State var expanded = false

    private var isOn: Bool { store.states[id] ?? false }
    private var isDisabled: Bool { store.disabled.contains(id) }
    private var isBusy: Bool { store.busy.contains(id) }
    private var hasOptions: Bool { id == .keepAwake }

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if expanded && hasOptions {
                durationList
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
                if let sub = store.subtitles[id] {
                    Text(sub)
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
        .help("选择时长")
    }

    private var durationList: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 10).opacity(0.6)
            VStack(spacing: 1) {
                ForEach(SwitchStore.awakeOptions, id: \.self) { m in
                    DurationOption(
                        title: SwitchStore.durationText(m),
                        selected: m == store.awakeMinutes,
                        running: isOn && m == store.awakeMinutes
                    ) {
                        store.startKeepAwake(minutes: m)
                        withAnimation(.snappy(duration: 0.25)) { expanded = false }
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
        }
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

private struct DurationOption: View {
    let title: String
    let selected: Bool
    let running: Bool
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
                Text(title)
                    .font(.system(size: 12.5, weight: selected ? .semibold : .regular))
                Spacer()
                if running {
                    Text("进行中")
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
                Text(title)
                if let subtitle { Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary) }
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
            Text(text)
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

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(get: { store.launchAtLogin }, set: { store.launchAtLogin = $0 })) {
                    SettingLabel(symbol: "power", color: .green, title: "登录时启动", subtitle: "开机后自动出现在菜单栏")
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
        .formStyle(.grouped)
        .frame(width: 580, height: 500)
        .onAppear { refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
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
            Text(title).font(.system(size: 12, weight: .semibold))
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
            Text("版本 \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
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
        .frame(width: 460, height: 380)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 15, weight: .semibold))
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }
}

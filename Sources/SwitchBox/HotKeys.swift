import AppKit
import Carbon.HIToolbox
import SwiftUI

// MARK: - 快捷键模型

struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32
    var display: String

    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let isFunctionKey = Self.functionKeys[Int(event.keyCode)] != nil
        // 必须带 ⌘ / ⌥ / ⌃ 之一（F 键除外），避免误触
        guard isFunctionKey || !flags.intersection([.command, .option, .control]).isEmpty else { return nil }

        var mods: UInt32 = 0
        var text = ""
        if flags.contains(.control) { mods |= UInt32(controlKey); text += "⌃" }
        if flags.contains(.option)  { mods |= UInt32(optionKey);  text += "⌥" }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey);   text += "⇧" }
        if flags.contains(.command) { mods |= UInt32(cmdKey);     text += "⌘" }
        text += Self.keyName(event)
        keyCode = UInt32(event.keyCode)
        carbonModifiers = mods
        display = text
    }

    private static let functionKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]
    private static let specialKeys: [Int: String] = [
        kVK_Space: String(localized: "空格"), kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
    ]

    private static func keyName(_ e: NSEvent) -> String {
        let code = Int(e.keyCode)
        if let f = functionKeys[code] { return f }
        if let s = specialKeys[code] { return s }
        return (e.charactersIgnoringModifiers ?? "?").uppercased()
    }
}

// MARK: - 全局快捷键注册（Carbon，无需辅助功能权限）

final class HotKeyCenter {
    static let shared = HotKeyCenter()
    private var refs: [EventHotKeyRef] = []
    private var idMap: [UInt32: SwitchID] = [:]
    private var current: [SwitchID: Shortcut] = [:]
    var handler: ((SwitchID) -> Void)?

    private init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            let id = hk.id
            DispatchQueue.main.async { HotKeyCenter.shared.fire(id) }
            return noErr
        }, 1, &spec, nil, nil)
    }

    func register(_ map: [SwitchID: Shortcut]) {
        current = map
        unregisterAll()
        for (index, (sid, sc)) in map.enumerated() {
            let hkID = EventHotKeyID(signature: OSType(0x5357_4258), id: UInt32(index + 1)) // 'SWBX'
            var ref: EventHotKeyRef?
            if RegisterEventHotKey(sc.keyCode, sc.carbonModifiers, hkID, GetApplicationEventTarget(), 0, &ref) == noErr,
               let ref {
                refs.append(ref)
                idMap[hkID.id] = sid
            }
        }
    }

    /// 录制快捷键期间暂停，避免触发已有快捷键
    func pause() { unregisterAll() }
    func resume() { register(current) }

    private func unregisterAll() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs.removeAll()
        idMap.removeAll()
    }

    private func fire(_ id: UInt32) {
        if let sid = idMap[id] { handler?(sid) }
    }
}

// MARK: - 快捷键录制控件

struct ShortcutRecorder: View {
    let shortcut: Shortcut?
    let onChange: (Shortcut?) -> Void
    @State private var recording = false
    @State private var monitor: Any?
    @State private var shake = false

    var body: some View {
        HStack(spacing: 6) {
            Button { recording ? stop() : start() } label: {
                HStack(spacing: 6) {
                    if recording {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text("按下快捷键…").foregroundStyle(.secondary)
                    } else if let shortcut {
                        Text(shortcut.display)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .kerning(1)
                    } else {
                        Text("录制快捷键").foregroundStyle(.tertiary)
                    }
                }
                .font(.system(size: 12))
                .frame(width: 118, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(recording ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(recording ? Color.accentColor : .clear, lineWidth: 1.5)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: shake ? -4 : 0)

            Button { onChange(nil) } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .opacity(shortcut != nil && !recording ? 1 : 0)
            .help("清除")
        }
        .onDisappear { stop() }
    }

    private func start() {
        recording = true
        HotKeyCenter.shared.pause()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
            if e.keyCode == UInt16(kVK_Escape) { stop(); return nil }
            if e.keyCode == UInt16(kVK_Delete) && e.modifierFlags.intersection([.command, .option, .control]).isEmpty {
                onChange(nil); stop(); return nil
            }
            if let sc = Shortcut(event: e) {
                onChange(sc); stop()
            } else {
                NSSound.beep()
                withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { shake = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
            }
            return nil
        }
    }

    private func stop() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        HotKeyCenter.shared.resume()
    }
}

// MARK: - 提示浮窗（类似系统音量提示）

final class HUD {
    static let shared = HUD()
    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(id: SwitchID, message: String, active: Bool) {
        hideWork?.cancel()
        let view = HUDView(id: id, message: message, active: active)
        let size = NSSize(width: 200, height: 200)

        let p: NSPanel
        if let panel { p = panel } else {
            p = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.level = .statusBar
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.ignoresMouseEvents = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel = p
        }
        p.contentView = NSHostingView(rootView: view)
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            p.setFrameOrigin(NSPoint(x: f.midX - size.width / 2, y: f.minY + f.height * 0.18))
        }
        p.alphaValue = 1
        p.orderFrontRegardless()

        let work = DispatchWorkItem { [weak p] in
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.35; p?.animator().alphaValue = 0 },
                                                 completionHandler: { p?.orderOut(nil) })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3, execute: work)
    }
}

private struct VisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct HUDView: View {
    let id: SwitchID
    let message: String
    let active: Bool

    var body: some View {
        VStack(spacing: 14) {
            SwitchIcon(id: id, size: 64, active: active)
            VStack(spacing: 3) {
                Text(id.title).font(.system(size: 14, weight: .semibold))
                Text(message).font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .background(VisualEffect())
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
    }
}

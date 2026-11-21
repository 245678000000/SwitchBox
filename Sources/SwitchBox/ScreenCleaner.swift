import AppKit
import SwiftUI

final class CleanerState: ObservableObject {
    @Published var holding = false
}

/// 屏幕清洁：全屏黑色遮罩并吞掉所有按键，长按 Esc 3 秒退出。
final class ScreenCleaner {
    private var windows: [NSWindow] = []
    private var monitor: Any?
    private var escTimer: Timer?
    private var savedOptions: NSApplication.PresentationOptions = []
    private let state = CleanerState()
    static let holdSeconds: Double = 3
    var onFinish: (() -> Void)?

    var isOn: Bool { !windows.isEmpty }

    private final class KeyWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    func start() {
        guard windows.isEmpty else { return }
        NSApp.activate(ignoringOtherApps: true)
        for screen in NSScreen.screens {
            let w = KeyWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            w.level = .screenSaver
            w.backgroundColor = .black
            w.isOpaque = true
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            w.contentView = NSHostingView(rootView: CleanerOverlay(state: state, isMain: screen == NSScreen.main))
            w.setFrame(screen.frame, display: true)
            w.alphaValue = 0
            w.makeKeyAndOrderFront(nil)
            windows.append(w)
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            windows.forEach { $0.animator().alphaValue = 1 }
        }
        savedOptions = NSApp.presentationOptions
        NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching,
                                     .disableForceQuit, .disableSessionTermination, .disableHideApplication]
        NSCursor.hide()

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged, .systemDefined]) { [weak self] event in
            if event.type == .keyDown, event.keyCode == 53, !event.isARepeat { self?.armEsc() }
            if event.type == .keyUp, event.keyCode == 53 { self?.disarmEsc() }
            return nil // 吞掉所有按键
        }
    }

    private func armEsc() {
        escTimer?.invalidate()
        state.holding = true
        escTimer = Timer.scheduledTimer(withTimeInterval: Self.holdSeconds, repeats: false) { [weak self] _ in
            if CGEventSource.keyState(.combinedSessionState, key: 53) { self?.stop() } else { self?.disarmEsc() }
        }
    }

    private func disarmEsc() {
        escTimer?.invalidate(); escTimer = nil
        state.holding = false
    }

    func stop() {
        disarmEsc()
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        NSApp.presentationOptions = savedOptions
        NSCursor.unhide()
        let closing = windows
        windows.removeAll()
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            closing.forEach { $0.animator().alphaValue = 0 }
        }, completionHandler: {
            closing.forEach { $0.orderOut(nil) }
        })
        onFinish?()
    }
}

private struct CleanerOverlay: View {
    @ObservedObject var state: CleanerState
    let isMain: Bool
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black
            if isMain {
                VStack(spacing: 18) {
                    ZStack {
                        Circle().stroke(.white.opacity(0.08), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "bubbles.and.sparkles.fill")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(width: 84, height: 84)

                    Text("屏幕清洁中")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("键盘已锁定，可以放心擦拭")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                    HStack(spacing: 6) {
                        Text("长按")
                        Text("esc")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 7).frame(height: 20)
                            .background(RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.3)))
                        Text("3 秒退出")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 6)
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: state.holding) { _, holding in
            if holding {
                withAnimation(.linear(duration: ScreenCleaner.holdSeconds)) { progress = 1 }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
            }
        }
    }
}

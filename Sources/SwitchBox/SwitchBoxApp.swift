import SwiftUI

@main
struct SwitchBoxApp: App {
    @StateObject private var store = SwitchStore.shared

    init() { DevTools.handleArguments() }

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(store: store)
        } label: {
            Image(systemName: store.menuIcon)
        }
        .menuBarExtraStyle(.window)

        Settings {
            PrefsView(store: store)
        }
    }
}

/// 开发用：`SwitchBox --render-icon out.png` 生成 App 图标，`--snapshot dir` 导出界面截图
enum DevTools {
    @MainActor static func handleArguments() {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--render-icon"), i + 1 < args.count {
            let r = ImageRenderer(content: AppIconView(size: 1024))
            r.scale = 1
            if let img = r.nsImage { write(img, to: args[i + 1]) }
            exit(0)
        }
        if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
            _ = NSApplication.shared
            NSApp.setActivationPolicy(.accessory)
            let dir = args[i + 1]
            let store = SwitchStore.shared
            for scheme in [ColorScheme.light, .dark] {
                let tag = scheme == .light ? "light" : "dark"
                snap(MenuPanel(store: store), scheme, "\(dir)/menu-\(tag).png")
                snap(GeneralTab(store: store), scheme, "\(dir)/general-\(tag).png")
                snap(CustomizeTab(store: store), scheme, "\(dir)/customize-\(tag).png")
                snap(ShortcutsTab(store: store), scheme, "\(dir)/shortcuts-\(tag).png")
                snap(AboutTab(), scheme, "\(dir)/about-\(tag).png")
            }
            exit(0)
        }
    }

    @MainActor private static func snap<V: View>(_ view: V, _ scheme: ColorScheme, _ path: String) {
        let root = view
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, scheme)
        let host = NSHostingView(rootView: root)
        host.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        let size = host.fittingSize
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = host.appearance
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }

    private static func write(_ img: NSImage, to path: String) {
        guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }
}

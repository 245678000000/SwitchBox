import SwiftUI

/// 开发用：把界面截图合成为 README 用的展示图。
/// 用法：SwitchBox --showcase <截图目录> <输出目录> <en|zh>
enum Showcase {
    @MainActor static func render(from src: String, to out: String, lang: String) {
        func img(_ name: String) -> NSImage? { NSImage(contentsOfFile: "\(src)/\(name).png") }
        let zh = lang.hasPrefix("zh")
        try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

        if let light = img("menu-light"), let dark = img("menu-dark") {
            save(HeroCanvas(light: light, dark: dark), "\(out)/hero.png")
        }
        if let g = img("general-light") {
            save(WindowCanvas(image: g, title: zh ? "通用" : "General", dark: false,
                              background: .init(h: 0.58, s: 0.30, b: 0.97)), "\(out)/settings-general.png")
        }
        if let c = img("customize-light") {
            save(WindowCanvas(image: c, title: zh ? "自定义" : "Customize", dark: false,
                              background: .init(h: 0.42, s: 0.25, b: 0.95)), "\(out)/settings-customize.png")
        }
        if let s = img("shortcuts-dark") {
            save(WindowCanvas(image: s, title: zh ? "快捷键" : "Shortcuts", dark: true,
                              background: .init(h: 0.74, s: 0.45, b: 0.55)), "\(out)/settings-shortcuts.png")
        }
        if let a = img("awake-light"), let d = img("darkopts-light") {
            save(OptionsCanvas(first: d, second: a), "\(out)/inline-options.png")
        }
    }

    @MainActor private static func save<V: View>(_ view: V, _ path: String) {
        let r = ImageRenderer(content: view)
        r.scale = 1
        guard let tiff = r.nsImage?.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }
}

struct HSB { let h: Double, s: Double, b: Double
    init(h: Double, s: Double, b: Double) { self.h = h; self.s = s; self.b = b }
    var color: Color { Color(hue: h, saturation: s, brightness: b) }
}

// MARK: - 背景

private struct Backdrop: View {
    let base: HSB
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hue: base.h, saturation: base.s * 0.7, brightness: min(1, base.b + 0.05)),
                                    Color(hue: base.h + 0.06, saturation: min(1, base.s * 1.2), brightness: base.b * 0.85)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color(hue: base.h - 0.05, saturation: base.s, brightness: 1).opacity(0.45))
                .frame(width: 900).blur(radius: 160).offset(x: -420, y: -300)
            Circle().fill(Color(hue: base.h + 0.12, saturation: base.s, brightness: 1).opacity(0.35))
                .frame(width: 800).blur(radius: 160).offset(x: 480, y: 340)
        }
    }
}

// MARK: - 菜单面板（浅色 + 深色）

private struct HeroCanvas: View {
    let light: NSImage, dark: NSImage
    var body: some View {
        ZStack {
            Backdrop(base: .init(h: 0.63, s: 0.55, b: 0.92))
            HStack(alignment: .top, spacing: 70) {
                panel(light).offset(y: -20)
                panel(dark).offset(y: 40)
            }
        }
        .frame(width: 1800, height: 1320)
        .clipped()
    }

    private func panel(_ image: NSImage) -> some View {
        let w: CGFloat = 640
        let h = w * image.size.height / image.size.width
        return Image(nsImage: image)
            .resizable()
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.black.opacity(0.12), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.35), radius: 50, y: 30)
    }
}

// MARK: - 设置窗口

private struct WindowCanvas: View {
    let image: NSImage
    let title: String
    let dark: Bool
    let background: HSB

    var body: some View {
        let w: CGFloat = 1160
        let h = w * image.size.height / image.size.width
        ZStack {
            Backdrop(base: background)
            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 16) {
                        Circle().fill(Color(red: 1, green: 0.37, blue: 0.34))
                        Circle().fill(Color(red: 1, green: 0.74, blue: 0.18))
                        Circle().fill(Color(red: 0.16, green: 0.79, blue: 0.25))
                        Spacer()
                    }
                    .frame(height: 24)
                    .padding(.horizontal, 28)
                    Text(title)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(dark ? .white.opacity(0.85) : .black.opacity(0.8))
                }
                .frame(height: 76)
                .background(dark ? Color(white: 0.17) : Color(white: 0.985))
                Rectangle().fill(dark ? .black.opacity(0.6) : .black.opacity(0.08)).frame(height: 1.5)
                Image(nsImage: image)
                    .resizable()
                    .frame(width: w, height: h)
            }
            .frame(width: w)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.black.opacity(dark ? 0.6 : 0.12), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.35), radius: 60, y: 34)
        }
        .frame(width: w + 240, height: h + 76 + 200)
        .clipped()
    }
}

// MARK: - 菜单内展开选项

private struct OptionsCanvas: View {
    let first: NSImage, second: NSImage
    var body: some View {
        ZStack {
            Backdrop(base: .init(h: 0.08, s: 0.45, b: 0.98))
            HStack(alignment: .top, spacing: 60) {
                card(first)
                card(second)
            }
        }
        .frame(width: 1600, height: 980)
        .clipped()
    }

    private func card(_ image: NSImage) -> some View {
        let w: CGFloat = 640
        let h = w * image.size.height / image.size.width
        return Image(nsImage: image)
            .resizable()
            .frame(width: w, height: h)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(.black.opacity(0.1), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.25), radius: 40, y: 24)
    }
}

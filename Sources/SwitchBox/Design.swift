import SwiftUI

// MARK: - 配色

struct Tint {
    let h: Double, s: Double, b: Double
    var top: Color { Color(hue: h, saturation: max(0, s - 0.12), brightness: min(1, b + 0.08)) }
    var bottom: Color { Color(hue: h, saturation: s, brightness: b - 0.04) }
    var base: Color { Color(hue: h, saturation: s, brightness: b) }
    var gradient: LinearGradient { LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom) }
}

extension SwitchID {
    var palette: Tint {
        switch self {
        case .hideDesktop:     Tint(h: 0.595, s: 0.78, b: 0.98)
        case .darkMode:        Tint(h: 0.690, s: 0.62, b: 0.86)
        case .keepAwake:       Tint(h: 0.075, s: 0.72, b: 0.92)
        case .screenSaver:     Tint(h: 0.780, s: 0.58, b: 0.88)
        case .nightShift:      Tint(h: 0.110, s: 0.85, b: 0.98)
        case .screenClean:     Tint(h: 0.500, s: 0.72, b: 0.80)
        case .emptyTrash:      Tint(h: 0.600, s: 0.08, b: 0.58)
        case .ejectDisks:      Tint(h: 0.555, s: 0.75, b: 0.90)
        case .micMute:         Tint(h: 0.990, s: 0.72, b: 0.94)
        case .dockAutohide:    Tint(h: 0.380, s: 0.68, b: 0.76)
        case .menuBarAutohide: Tint(h: 0.450, s: 0.66, b: 0.74)
        case .showHiddenFiles: Tint(h: 0.930, s: 0.60, b: 0.92)
        }
    }
}

// MARK: - 图标方块

struct SwitchIcon: View {
    let id: SwitchID
    var size: CGFloat = 28
    var active: Bool = true

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
        ZStack {
            if active {
                shape.fill(id.palette.gradient)
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 0.6)
            } else {
                shape.fill(Color.primary.opacity(0.07))
                shape.strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
            Image(systemName: id.symbol)
                .font(.system(size: size * 0.46, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(active ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
        }
        .frame(width: size, height: size)
        .shadow(color: active ? id.palette.base.opacity(0.35) : .clear, radius: size * 0.12, y: size * 0.05)
        .animation(.easeOut(duration: 0.18), value: active)
    }
}

// MARK: - App 图标

struct AppIconView: View {
    var size: CGFloat = 1024

    var body: some View {
        let s = size
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hue: 0.62, saturation: 0.70, brightness: 0.98),
                             Color(hue: 0.70, saturation: 0.80, brightness: 0.62)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                .fill(RadialGradient(colors: [.white.opacity(0.28), .clear],
                                     center: .init(x: 0.3, y: 0.15), startRadius: 0, endRadius: s * 0.75))
            VStack(spacing: s * 0.085) {
                pill(on: true)
                pill(on: false)
            }
        }
        .frame(width: s * 0.82, height: s * 0.82)
        .shadow(color: .black.opacity(0.3), radius: s * 0.025, y: s * 0.012)
        .frame(width: s, height: s)
    }

    private func pill(on: Bool) -> some View {
        let w = size * 0.50, h = size * 0.20
        return ZStack(alignment: on ? .trailing : .leading) {
            Capsule().fill(on ? Color.white.opacity(0.95) : Color.white.opacity(0.22))
            Circle()
                .fill(on ? Color(hue: 0.62, saturation: 0.75, brightness: 0.92) : .white)
                .padding(h * 0.14)
                .shadow(color: .black.opacity(0.25), radius: h * 0.06, y: h * 0.03)
        }
        .frame(width: w, height: h)
    }
}

// MARK: - 悬停按钮

struct HoverIconButton: View {
    let symbol: String
    let help: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(hovering ? .primary : .secondary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.primary.opacity(hovering ? 0.08 : 0)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct PillButtonStyle: ButtonStyle {
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 14)
            .frame(height: 28)
            .background(Capsule().fill(Color.primary.opacity(configuration.isPressed ? 0.16 : 0.07)))
            .contentShape(Capsule())
    }
}

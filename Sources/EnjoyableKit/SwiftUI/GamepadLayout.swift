import SwiftUI

enum GamepadControl: String, CaseIterable, Hashable {
    case dpadUp
    case dpadDown
    case dpadLeft
    case dpadRight
    case leftStickPress
    case rightStickPress
    case leftStickUp
    case leftStickDown
    case leftStickLeft
    case leftStickRight
    case rightStickUp
    case rightStickDown
    case rightStickLeft
    case rightStickRight
    case faceNorth
    case faceSouth
    case faceWest
    case faceEast
    case leftShoulder
    case rightShoulder
    case leftTrigger
    case rightTrigger
    case start
    case select
    case home
    case touchpad

    var title: String {
        switch self {
        case .dpadUp: return "DU"
        case .dpadDown: return "DD"
        case .dpadLeft: return "DL"
        case .dpadRight: return "DR"
        case .leftStickPress: return "LS"
        case .rightStickPress: return "RS"
        case .leftStickUp: return "LU"
        case .leftStickDown: return "LD"
        case .leftStickLeft: return "LL"
        case .leftStickRight: return "LR"
        case .rightStickUp: return "RU"
        case .rightStickDown: return "RD"
        case .rightStickLeft: return "RL"
        case .rightStickRight: return "RR"
        case .faceNorth: return "Y"
        case .faceSouth: return "A"
        case .faceWest: return "X"
        case .faceEast: return "B"
        case .leftShoulder: return "LB"
        case .rightShoulder: return "RB"
        case .leftTrigger: return "LT"
        case .rightTrigger: return "RT"
        case .start: return "ST"
        case .select: return "SE"
        case .home: return "PS"
        case .touchpad: return "TP"
        }
    }
}

enum GamepadLayoutMapper {
    private enum ButtonProfile {
        case standard
        case playStation
    }

    static func control(for inputUID: String) -> GamepadControl? {
        let parts = inputUID.split(separator: "~").map(String.init)
        guard parts.count >= 2 else { return nil }

        if let button = parseButton(parts) {
            return button
        }
        if let axis = parseAxis(parts) {
            return axis
        }
        if let hat = parseHat(parts) {
            return hat
        }
        return nil
    }

    private static func parseButton(_ parts: [String]) -> GamepadControl? {
        guard let item = parts.last(where: { $0.hasPrefix("Button ") }),
              let index = Int(item.dropFirst("Button ".count))
        else { return nil }

        let profile = buttonProfile(deviceUID: parts[0])

        switch index {
        case 1:
            return profile == .playStation ? .faceWest : .faceSouth
        case 2:
            return profile == .playStation ? .faceSouth : .faceEast
        case 3:
            return profile == .playStation ? .faceEast : .faceWest
        case 4:
            return .faceNorth
        case 5: return .leftShoulder
        case 6: return .rightShoulder
        case 7: return .leftTrigger
        case 8: return .rightTrigger
        case 9: return .select
        case 10: return .start
        case 11: return .leftStickPress
        case 12: return .rightStickPress
        case 13: return .home
        case 14: return .touchpad
        default: return nil
        }
    }

    private static func buttonProfile(deviceUID: String) -> ButtonProfile {
        let pieces = deviceUID.split(separator: ":")
        guard pieces.count >= 2, let vendorID = Int(pieces[0]) else {
            return .standard
        }
        // Sony controllers (DualShock/DualSense) report face button order as □ × ○ △.
        if vendorID == 1356 {
            return .playStation
        }
        return .standard
    }

    private static func parseAxis(_ parts: [String]) -> GamepadControl? {
        guard let axisItem = parts.first(where: { $0.hasPrefix("Axis ") }),
              let axisIndex = Int(axisItem.dropFirst("Axis ".count)),
              let direction = parts.last
        else { return nil }

        switch (axisIndex, direction) {
        case (1, "Low"): return .leftStickLeft
        case (1, "High"): return .leftStickRight
        case (2, "Low"): return .leftStickUp
        case (2, "High"): return .leftStickDown
        case (3, "Low"): return .rightStickLeft
        case (3, "High"): return .rightStickRight
        case (4, "Low"): return .rightStickUp
        case (4, "High"): return .rightStickDown
        default: return nil
        }
    }

    private static func parseHat(_ parts: [String]) -> GamepadControl? {
        guard parts.contains(where: { $0.hasPrefix("Hat Switch ") }),
              let direction = parts.last
        else { return nil }

        switch direction {
        case "Up": return .dpadUp
        case "Down": return .dpadDown
        case "Left": return .dpadLeft
        case "Right": return .dpadRight
        default: return nil
        }
    }
}

struct ControlHighlightTracker {
    private(set) var activeControls: Set<GamepadControl> = []
    private(set) var releaseDecayDeadline: [GamepadControl: Date] = [:]
    let releaseDecay: TimeInterval

    init(releaseDecay: TimeInterval = 0.16) {
        self.releaseDecay = releaseDecay
    }

    mutating func handle(control: GamepadControl, isActive: Bool, now: Date = Date()) {
        if isActive {
            activeControls.insert(control)
            releaseDecayDeadline.removeValue(forKey: control)
        } else {
            if activeControls.remove(control) != nil {
                releaseDecayDeadline[control] = now.addingTimeInterval(releaseDecay)
            }
        }
    }

    mutating func visibleControls(now: Date = Date()) -> Set<GamepadControl> {
        releaseDecayDeadline = releaseDecayDeadline.filter { $0.value > now }
        return activeControls.union(releaseDecayDeadline.keys)
    }
}

struct GamepadLayoutView: View {
    @Environment(\.colorScheme) private var colorScheme
    let highlightedControls: Set<GamepadControl>

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(GamepadControl.allCases, id: \.self) { control in
                    gamepadButton(control, size: geometry.size)
                }
                centerHint(size: geometry.size)
            }
            .overlay(
                Text("Live Input")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(liveBadgeTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(liveBadgeBackgroundColor)
                            .overlay(
                                Capsule()
                                    .stroke(liveBadgeBorderColor, lineWidth: 1)
                            )
                    )
                    .padding(10),
                alignment: .topLeading
            )
        }
        .frame(height: 250)
        
    }

    @ViewBuilder
    private func controllerShell(size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        let shell = shellFillColor

        Circle()
            .fill(shell)
            .frame(width: w * 0.54, height: h * 0.84)
            .position(x: w * 0.30, y: h * 0.57)

        Circle()
            .fill(shell)
            .frame(width: w * 0.54, height: h * 0.84)
            .position(x: w * 0.70, y: h * 0.57)

        RoundedRectangle(cornerRadius: 22)
            .fill(shell.opacity(0.9))
            .frame(width: w * 0.38, height: h * 0.34)
            .position(x: w * 0.50, y: h * 0.46)

        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.secondary.opacity(0.20), lineWidth: 1)
            .frame(width: w * 0.52, height: h * 0.20)
            .position(x: w * 0.50, y: h * 0.16)
    }

    @ViewBuilder
    private func gamepadButton(_ control: GamepadControl, size: CGSize) -> some View {
        let p = position(for: control, size: size)
        let isActive = highlightedControls.contains(control)
        let isMajor = isMajorControl(control)
        let diameter: CGFloat = isMajor ? 32 : 26

        Text(control.title)
            .font(.system(size: isMajor ? 11 : 10, weight: .semibold, design: .rounded))
            .foregroundColor(isActive ? .white : .primary)
            .frame(width: diameter, height: diameter)
            .background(
                Circle()
                    .fill(isActive ? Color.accentColor : inactiveButtonFillColor)
            )
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(isActive ? 0.0 : 0.12), lineWidth: 1)
            )
            .shadow(color: isActive ? Color.accentColor.opacity(0.45) : .clear, radius: 8, x: 0, y: 0)
            .position(x: p.x, y: p.y)
    }

    @ViewBuilder
    private func centerHint(size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
            Text("按下手柄按键可看到对应高亮")
                .font(.system(size: 11))
                .foregroundColor(hintTextColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(hintBackgroundColor)
                .overlay(
                    Capsule()
                        .stroke(hintBorderColor, lineWidth: 1)
                )
        )
        .position(x: w * 0.50, y: h * 0.95)
    }

    private var liveBadgeTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.72)
    }

    private var panelGradientTopColor: Color {
        Color(red: 0.985, green: 0.985, blue: 0.99)
    }

    private var panelGradientBottomColor: Color {
        Color(red: 0.94, green: 0.95, blue: 0.97)
    }

    private var shellFillColor: Color {
        Color.black.opacity(0.05)
    }

    private var liveBadgeBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.88)
    }

    private var liveBadgeBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.10)
    }

    private var inactiveButtonFillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.10)
    }

    private var hintTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.82) : Color.black.opacity(0.68)
    }

    private var hintBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.92)
    }

    private var hintBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.09)
    }

    private func isMajorControl(_ control: GamepadControl) -> Bool {
        switch control {
        case .faceNorth, .faceSouth, .faceWest, .faceEast, .leftStickPress, .rightStickPress, .dpadUp, .dpadDown, .dpadLeft, .dpadRight:
            return true
        default:
            return false
        }
    }

    private func position(for control: GamepadControl, size: CGSize) -> CGPoint {
        let w = size.width
        let h = size.height
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: w * x, y: h * y)
        }

        switch control {
        case .leftShoulder: return point(0.24, 0.16)
        case .rightShoulder: return point(0.76, 0.16)
        case .leftTrigger: return point(0.15, 0.16)
        case .rightTrigger: return point(0.85, 0.16)

        case .dpadUp: return point(0.17, 0.51)
        case .dpadDown: return point(0.17, 0.71)
        case .dpadLeft: return point(0.10, 0.61)
        case .dpadRight: return point(0.24, 0.61)

        case .leftStickPress: return point(0.35, 0.72)
        case .leftStickUp: return point(0.35, 0.58)
        case .leftStickDown: return point(0.35, 0.86)
        case .leftStickLeft: return point(0.28, 0.72)
        case .leftStickRight: return point(0.42, 0.72)

        case .rightStickPress: return point(0.65, 0.72)
        case .rightStickUp: return point(0.65, 0.58)
        case .rightStickDown: return point(0.65, 0.86)
        case .rightStickLeft: return point(0.58, 0.72)
        case .rightStickRight: return point(0.72, 0.72)

        case .faceNorth: return point(0.83, 0.51)
        case .faceSouth: return point(0.83, 0.71)
        case .faceWest: return point(0.76, 0.61)
        case .faceEast: return point(0.90, 0.61)

        case .start: return point(0.55, 0.45)
        case .select: return point(0.45, 0.45)
        case .home: return point(0.50, 0.52)
        case .touchpad: return point(0.50, 0.33)
        }
    }
}

#if DEBUG
struct GamepadLayoutView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            GamepadLayoutView(
                highlightedControls: [.faceSouth, .rightTrigger, .leftStickRight, .dpadUp]
            )
            .frame(width: 760)

            GamepadLayoutView(
                highlightedControls: [.faceEast, .faceNorth, .rightStickPress]
            )
            .frame(width: 760)
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
        .previewLayout(.sizeThatFits)
    }
}
#endif

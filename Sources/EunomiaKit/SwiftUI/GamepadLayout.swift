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

    var symbol: String {
        switch self {
        case .dpadUp: return "chevron.up.circle"
        case .dpadDown: return "chevron.down.circle"
        case .dpadLeft: return "chevron.left.circle"
        case .dpadRight: return "chevron.right.circle"
        case .leftStickPress: return "l.circle.fill"
        case .rightStickPress: return "r.circle.fill"
        case .leftStickUp: return "arrow.up.circle"
        case .leftStickDown: return "arrow.down.circle"
        case .leftStickLeft: return "arrow.left.circle"
        case .leftStickRight: return "arrow.right.circle"
        case .rightStickUp: return "arrow.up.circle"
        case .rightStickDown: return "arrow.down.circle"
        case .rightStickLeft: return "arrow.left.circle"
        case .rightStickRight: return "arrow.right.circle"
        case .faceNorth: return "y.circle.fill"
        case .faceSouth: return "a.circle.fill"
        case .faceWest: return "x.circle.fill"
        case .faceEast: return "b.circle.fill"
        case .leftShoulder: return "l1.rectangle.roundedbottom.fill"
        case .rightShoulder: return "r1.rectangle.roundedbottom.fill"
        case .leftTrigger: return "chevron.left.circle.fill"
        case .rightTrigger: return "chevron.right.circle.fill"
        case .start: return "arrowtriangle.right.fill"
        case .select: return "square.fill"
        case .home: return "house.fill"
        case .touchpad: return "hand.tap.fill"
        }
    }

    var accessibilityName: String {
        switch self {
        case .dpadUp: return "D-Pad Up"
        case .dpadDown: return "D-Pad Down"
        case .dpadLeft: return "D-Pad Left"
        case .dpadRight: return "D-Pad Right"
        case .leftStickPress: return "Left Stick Press"
        case .rightStickPress: return "Right Stick Press"
        case .leftStickUp: return "Left Stick Up"
        case .leftStickDown: return "Left Stick Down"
        case .leftStickLeft: return "Left Stick Left"
        case .leftStickRight: return "Left Stick Right"
        case .rightStickUp: return "Right Stick Up"
        case .rightStickDown: return "Right Stick Down"
        case .rightStickLeft: return "Right Stick Left"
        case .rightStickRight: return "Right Stick Right"
        case .faceNorth: return "Y"
        case .faceSouth: return "A"
        case .faceWest: return "X"
        case .faceEast: return "B"
        case .leftShoulder: return "Left Shoulder"
        case .rightShoulder: return "Right Shoulder"
        case .leftTrigger: return "Left Trigger"
        case .rightTrigger: return "Right Trigger"
        case .start: return "Start"
        case .select: return "Select"
        case .home: return "Home"
        case .touchpad: return "Touchpad"
        }
    }

    func accessibilityLabel(controlPrefix: String = L10n.text("control")) -> String {
        "\(controlPrefix) \(accessibilityName)"
    }

    var accessibilityIdentifier: String {
        "gamepad.control.\(rawValue)"
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

    static func possibleInputEIDs(for control: GamepadControl, deviceUID: String?) -> [String] {
        let profile = deviceUID.map(buttonProfile(deviceUID:)) ?? .standard

        switch control {
        case .faceSouth:
            return [profile == .playStation ? "Button 2" : "Button 1"]
        case .faceEast:
            return [profile == .playStation ? "Button 3" : "Button 2"]
        case .faceWest:
            return [profile == .playStation ? "Button 1" : "Button 3"]
        case .faceNorth:
            return ["Button 4"]
        case .leftShoulder:
            return ["Button 5"]
        case .rightShoulder:
            return ["Button 6"]
        case .leftTrigger:
            return ["Axis 5~High", "Axis 5~Low", "Button 7"]
        case .rightTrigger:
            return ["Axis 6~High", "Axis 6~Low", "Button 8"]
        case .select:
            return ["Button 9"]
        case .start:
            return ["Button 10"]
        case .leftStickPress:
            return ["Button 11"]
        case .rightStickPress:
            return ["Button 12"]
        case .home:
            return ["Button 13"]
        case .touchpad:
            return ["Button 14"]
        case .dpadUp:
            return ["Hat Switch 1~Up"]
        case .dpadDown:
            return ["Hat Switch 1~Down"]
        case .dpadLeft:
            return ["Hat Switch 1~Left"]
        case .dpadRight:
            return ["Hat Switch 1~Right"]
        case .leftStickLeft:
            return ["Axis 1~Low"]
        case .leftStickRight:
            return ["Axis 1~High"]
        case .leftStickUp:
            return ["Axis 2~Low"]
        case .leftStickDown:
            return ["Axis 2~High"]
        case .rightStickLeft:
            return ["Axis 3~Low"]
        case .rightStickRight:
            return ["Axis 3~High"]
        case .rightStickUp:
            return ["Axis 4~Low"]
        case .rightStickDown:
            return ["Axis 4~High"]
        }
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
        case (5, _): return .leftTrigger
        case (6, _): return .rightTrigger
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
    let canConfigureControl: (GamepadControl) -> Bool
    let onConfigureKeyPress: (GamepadControl) -> Void
    let onClearMapping: (GamepadControl) -> Void

    init(
        highlightedControls: Set<GamepadControl>,
        canConfigureControl: @escaping (GamepadControl) -> Bool = { _ in false },
        onConfigureKeyPress: @escaping (GamepadControl) -> Void = { _ in },
        onClearMapping: @escaping (GamepadControl) -> Void = { _ in }
    ) {
        self.highlightedControls = highlightedControls
        self.canConfigureControl = canConfigureControl
        self.onConfigureKeyPress = onConfigureKeyPress
        self.onClearMapping = onClearMapping
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                controllerShell(size: geometry.size)

                ForEach(GamepadControl.allCases, id: \.self) { control in
                    gamepadButton(control, size: geometry.size)
                }
                centerHint(size: geometry.size)
            }
            .overlay(
                Text(L10n.text("live_input"))
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
        .frame(height: 320)
        
    }

    @ViewBuilder
    private func controllerShell(size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        let shell = shellFillColor
        
        // Main White Body & Grips (DualSense Silhouette)
        Path { path in
            // Top edge
            path.move(to: CGPoint(x: w * 0.32, y: h * 0.28))
            path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.28))
            
            // Right Shoulder to Grip
            path.addCurve(to: CGPoint(x: w * 0.94, y: h * 0.48),
                          control1: CGPoint(x: w * 0.85, y: h * 0.28),
                          control2: CGPoint(x: w * 0.94, y: h * 0.38))
            
            path.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.94),
                          control1: CGPoint(x: w * 0.94, y: h * 0.75),
                          control2: CGPoint(x: w * 0.88, y: h * 0.9))
            
            // Bottom center curve
            path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.82),
                          control1: CGPoint(x: w * 0.68, y: h * 0.98),
                          control2: CGPoint(x: w * 0.58, y: h * 0.82))
            
            path.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.94),
                          control1: CGPoint(x: w * 0.42, y: h * 0.82),
                          control2: CGPoint(x: w * 0.32, y: h * 0.98))
            
            // Left Grip to Shoulder
            path.addCurve(to: CGPoint(x: w * 0.06, y: h * 0.48),
                          control1: CGPoint(x: w * 0.12, y: h * 0.9),
                          control2: CGPoint(x: w * 0.06, y: h * 0.75))
            
            path.addCurve(to: CGPoint(x: w * 0.32, y: h * 0.28),
                          control1: CGPoint(x: w * 0.06, y: h * 0.38),
                          control2: CGPoint(x: w * 0.15, y: h * 0.28))
            
            path.closeSubpath()
        }
        .fill(shell)

        // Large Center Touchpad
        RoundedRectangle(cornerRadius: 12)
            .fill(shell.opacity(0.7))
            .frame(width: w * 0.38, height: h * 0.32)
            .position(x: w * 0.5, y: h * 0.46)
            
        // Inner Black Section (V-shape around sticks)
        Path { path in
            path.move(to: CGPoint(x: w * 0.3, y: h * 0.58))
            path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.82), control: CGPoint(x: w * 0.4, y: h * 0.65))
            path.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.58), control: CGPoint(x: w * 0.6, y: h * 0.65))
            path.addQuadCurve(to: CGPoint(x: w * 0.3, y: h * 0.58), control: CGPoint(x: w * 0.5, y: h * 0.62))
        }
        .fill(Color.primary.opacity(0.06))

        // Shoulder hints
        Group {
            Capsule().fill(shell.opacity(0.9)).frame(width: w * 0.18, height: h * 0.08).position(x: w * 0.26, y: h * 0.24)
            Capsule().fill(shell.opacity(0.9)).frame(width: w * 0.18, height: h * 0.08).position(x: w * 0.74, y: h * 0.24)
        }
    }

    @ViewBuilder
    private func gamepadButton(_ control: GamepadControl, size: CGSize) -> some View {
        let p = position(for: control, size: size)
        let isActive = highlightedControls.contains(control)
        let isMajor = isMajorControl(control)
        let diameter: CGFloat = isMajor ? 36 : 28

        Button {
            onConfigureKeyPress(control)
        } label: {
            ZStack {
                Circle()
                    .fill(isActive ? Color.accentColor : inactiveButtonFillColor)
                    .shadow(color: isActive ? Color.accentColor.opacity(0.5) : .clear, radius: 10)

                Image(systemName: control.symbol)
                    .font(.system(size: isMajor ? 14 : 11, weight: .semibold))
                    .foregroundColor(isActive ? .white : .primary.opacity(0.8))
            }
            .frame(width: diameter, height: diameter)
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(isActive ? 0.0 : 0.08), lineWidth: 1)
            )
            .contentShape(Circle())
        }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(control.accessibilityLabel()))
            .accessibilityHint(Text(L10n.text("menu_key_detail")))
            .accessibilityIdentifier(control.accessibilityIdentifier)
            .position(x: p.x, y: p.y)
            .zIndex(isActive ? 2 : 1)
            .contextMenu {
                Button(L10n.text("menu_key_detail")) {
                    onConfigureKeyPress(control)
                }
                Button(L10n.text("delete_binding")) {
                    onClearMapping(control)
                }
            }
    }

    @ViewBuilder
    private func centerHint(size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
            Text(L10n.text("controller_hint_press_to_highlight"))
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

    private var shellFillColor: Color {
        Color.primary.opacity(0.04)
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
        case .leftShoulder: return point(0.26, 0.28)
        case .rightShoulder: return point(0.74, 0.28)
        case .leftTrigger: return point(0.20, 0.20)
        case .rightTrigger: return point(0.80, 0.20)

        // Flanking the touchpad
        case .dpadUp: return point(0.20, 0.44)
        case .dpadDown: return point(0.20, 0.58)
        case .dpadLeft: return point(0.15, 0.51)
        case .dpadRight: return point(0.25, 0.51)

        case .faceNorth: return point(0.80, 0.44)
        case .faceSouth: return point(0.80, 0.58)
        case .faceWest: return point(0.75, 0.51)
        case .faceEast: return point(0.85, 0.51)

        // Parallel sticks at bottom center
        case .leftStickPress: return point(0.38, 0.68)
        case .leftStickUp: return point(0.38, 0.60)
        case .leftStickDown: return point(0.38, 0.76)
        case .leftStickLeft: return point(0.33, 0.68)
        case .leftStickRight: return point(0.43, 0.68)

        case .rightStickPress: return point(0.62, 0.68)
        case .rightStickUp: return point(0.62, 0.60)
        case .rightStickDown: return point(0.62, 0.76)
        case .rightStickLeft: return point(0.57, 0.68)
        case .rightStickRight: return point(0.67, 0.68)

        case .start: return point(0.64, 0.40) // Options
        case .select: return point(0.36, 0.40) // Create
        case .home: return point(0.50, 0.72)   // PS Button
        case .touchpad: return point(0.50, 0.46)
        }
    }
}

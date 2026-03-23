import SwiftUI

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

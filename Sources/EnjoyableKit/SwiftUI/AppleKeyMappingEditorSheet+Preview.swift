import SwiftUI
import ComposableArchitecture

#if DEBUG
struct AppleKeyMappingEditorSheet_Previews: PreviewProvider {
    static var previews: some View {
        AppleKeyMappingEditorSheet(
            store: Store(
                initialState: AppleKeyMappingEditorFeature.State(
                    initialState: .init(
                inputID: "preview~button~1",
                inputPath: "DualSense 5 / Button 1",
                enabled: true,
                keyCode: 0x00,
                keySequenceSteps: [
                    NJKeySequenceStep(keys: [0x00], delayMilliseconds: 0),
                    NJKeySequenceStep(keys: [0x0B], delayMilliseconds: 80)
                ],
                activationThreshold: 0.55,
                isResolvable: true,
                unavailableReason: nil
                )
            )
            ) {
                AppleKeyMappingEditorFeature()
            }
        )
        .frame(width: 1000, height: 560)
    }
}
#endif

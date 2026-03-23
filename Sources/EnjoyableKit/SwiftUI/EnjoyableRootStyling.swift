import SwiftUI

enum NativeCardSurfaceStyle: Equatable {
    case adaptiveGlass
    case solid
}


extension View {
    @ViewBuilder
    func nativeTokenFieldStyle() -> some View {
        self
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    func nativeInputFieldBackground() -> some View {
        background(
            RoundedRectangle(
                cornerRadius: AppleNativeDesignMetrics.compactCardCornerRadius,
                style: .continuous
            )
            .fill(Color.white.opacity(AppleNativeDesignMetrics.inputFieldBackgroundOpacity))
        )
    }

    @ViewBuilder
    func nativeSidebarBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(
                AppleNativePalette.sidebarBackground.opacity(AppleNativeDesignMetrics.panelBackgroundOpacity)
            )
    }

    @ViewBuilder
    func nativeCardSurface(_ surfaceStyle: NativeCardSurfaceStyle = .adaptiveGlass) -> some View {
        if surfaceStyle == .solid {
            self
                .padding(AppleNativeDesignMetrics.spacingL)
                .background(
                    RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                        .stroke(AppleNativePalette.stroke, lineWidth: 1)
                )
        } else {
#if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                GlassEffectContainer {
                    self
                        .padding(AppleNativeDesignMetrics.spacingL)
                        .background(
                            RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                                .fill(Color.clear)
                                .glassEffect()
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                                .stroke(AppleNativePalette.stroke, lineWidth: 1)
                        )
                }
            } else {
                self
                    .padding(AppleNativeDesignMetrics.spacingL)
                    .background(
                        RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.82))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                            .stroke(AppleNativePalette.stroke, lineWidth: 1)
                    )
            }
#else
            self
                .padding(AppleNativeDesignMetrics.spacingL)
                .background(
                    RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppleNativeDesignMetrics.cardCornerRadius, style: .continuous)
                        .stroke(AppleNativePalette.stroke, lineWidth: 1)
                )
#endif
        }
    }
}

//
//  VisualEffectBlur.swift
//  boringNotch
//
//  NSVisualEffectView wrapper and Liquid Glass styling helpers.
//

import SwiftUI

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Liquid Glass Text & Icon Styling

extension View {
    /// Primary text on glass: white with subtle drop shadow for contrast.
    func glassText() -> some View {
        self
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 0.5)
    }

    /// Secondary/dimmed text on glass: lighter opacity with shadow.
    func glassSecondaryText() -> some View {
        self
            .foregroundStyle(.white.opacity(0.75))
            .shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5)
    }

    /// Icon styling on glass: white with subtle shadow.
    func glassIcon() -> some View {
        self
            .foregroundStyle(.white.opacity(0.9))
            .shadow(color: .black.opacity(0.3), radius: 1, y: 0.5)
    }

    /// Surface/card background for glass mode.
    func glassSurface(cornerRadius: CGFloat = 10) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.white.opacity(0.1))
                .shadow(color: .white.opacity(0.05), radius: 0.5, y: -0.5)
        )
    }

    /// Conditionally apply glass or solid styling.
    @ViewBuilder
    func adaptiveText(isGlass: Bool) -> some View {
        if isGlass {
            self.glassText()
        } else {
            self.foregroundStyle(.white)
        }
    }
}

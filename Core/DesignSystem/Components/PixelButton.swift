//
//  PixelButton.swift
//  UncoverYourPixels
//
//  앱 공통 가로 버튼. 화면마다 모서리·높이·글자가 제각각이던 것을 모은다.
//

import SwiftUI

struct PixelButton: View {
    enum Style {
        case primary     // 주요 동작 — 보라 그라데이션
        case solid       // 보조 주요 동작 — 단색 보라
        case secondary   // 테두리만
    }

    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fontSize: CGFloat = 22

    let action: () -> Void

    @State private var pressed = false

    private var active: Bool { isEnabled && !isLoading }

    var body: some View {
        Button(action: { if active { action() } }) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: fontSize * 0.7, weight: .semibold))
                        }
                        Text(title).font(AppFont.custom(fontSize))
                    }
                }
            }
            .foregroundColor(labelColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(borderColor, lineWidth: 1.5))
            .cornerRadius(AppRadius.md)
            .shadow(color: shadowColor, radius: 12, y: 5)
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
        }
        .buttonStyle(.plain)
        .disabled(!active)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if active { pressed = true } }
                .onEnded { _ in pressed = false }
        )
    }

    private var labelColor: Color {
        guard active else { return DTheme.purplePale.opacity(0.45) }
        switch style {
        case .primary, .solid: return .white
        case .secondary:       return DTheme.purplePale
        }
    }

    @ViewBuilder private var background: some View {
        if !active {
            DTheme.purpleDeep.opacity(0.75)
        } else {
            switch style {
            case .primary:
                LinearGradient(colors: [DTheme.purpleLight, DTheme.purple],
                               startPoint: .leading, endPoint: .trailing)
            case .solid:
                DTheme.purple
            case .secondary:
                Color.clear
            }
        }
    }

    private var borderColor: Color {
        guard active else { return DTheme.purpleDark.opacity(0.85) }
        switch style {
        case .primary:   return DTheme.purplePale.opacity(0.7)
        case .solid:     return DTheme.purpleLight
        case .secondary: return DTheme.purpleDeep
        }
    }

    private var shadowColor: Color {
        guard active else { return .clear }
        switch style {
        case .primary:   return DTheme.purple.opacity(0.45)
        case .solid:     return DTheme.purple.opacity(0.3)
        case .secondary: return .clear
        }
    }
}

#Preview("PixelButton") {
    ZStack {
        DTheme.bg.ignoresSafeArea()
        VStack(spacing: 18) {
            PixelButton(title: "다이어리에 저장하기") {}
            PixelButton(title: "저장하기", icon: "square.and.arrow.down.fill") {}
            PixelButton(title: "새 사진으로 퍼즐 만들기", icon: "plus", style: .solid, fontSize: 18) {}
            PixelButton(title: "게스트로 시작", style: .secondary, fontSize: 20) {}
            PixelButton(title: "저장 중", isLoading: true) {}
            PixelButton(title: "다이어리에 저장하기", isEnabled: false) {}
        }
        .padding(28)
    }
}

//
//  PixelCircleButton.swift
//  UncoverYourPixels
//
//  화면 좌상단의 원형 아이콘 버튼. 뒤로가기·닫기에 쓴다.
//

import SwiftUI

struct PixelCircleButton: View {
    let systemName: String
    var fill: Color = DTheme.bg2
    var border: Color = DTheme.purple
    var icon: Color = DTheme.purplePale
    var size: CGFloat = 36
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fill)
                    .overlay(Circle().stroke(border, lineWidth: 1.5))
                Image(systemName: systemName)
                    .font(.system(size: size * 0.39, weight: .semibold))
                    .foregroundColor(icon)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

#Preview("PixelCircleButton") {
    ZStack {
        DTheme.bg.ignoresSafeArea()
        HStack(spacing: 20) {
            PixelCircleButton(systemName: "chevron.left") {}
            PixelCircleButton(systemName: "xmark", fill: DTheme.surface) {}
            PixelCircleButton(systemName: "trash", border: DTheme.danger, icon: DTheme.danger) {}
        }
    }
}

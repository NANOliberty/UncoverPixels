//
//  PixelPanel.swift
//  UncoverYourPixels
//
//  각진 테두리 패널. 픽셀 아트 톤에 맞춰 모서리를 거의 주지 않는다.
//

import SwiftUI

struct PixelPanel<Content: View>: View {
    var fill: Color = DTheme.cardBg
    var border: Color = DTheme.cardEdge
    var borderWidth: CGFloat = 1.5
    var radius: CGFloat = 2
    /// 오른쪽 아래로 밀린 블록 그림자 — 픽셀 게임 UI의 입체 표현
    var blockShadow: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            if blockShadow {
                RoundedRectangle(cornerRadius: radius)
                    .fill(DTheme.purpleDeep)
                    .offset(x: 3, y: 3)
            }
            content()
                .background(RoundedRectangle(cornerRadius: radius).fill(fill))
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(border, lineWidth: borderWidth))
        }
    }
}

#Preview("PixelPanel") {
    ZStack {
        AuroraBackground()
        VStack(spacing: 24) {
            PixelPanel {
                Text("기본 패널").font(AppFont.body).foregroundColor(DTheme.textSoft)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
            }
            PixelPanel(border: DTheme.purpleLight, blockShadow: true) {
                Text("블록 그림자").font(AppFont.body).foregroundColor(DTheme.textSoft)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
            }
        }
        .padding(32)
    }
}

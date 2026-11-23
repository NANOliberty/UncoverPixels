//
//  PixelPanel.swift
//  UncoverYourPixels
//
//  내용을 감싸는 카드. 설정 묶음, 작품 목록 칸, 퍼즐 클리어 카드가 이것을 쓴다.
//

import SwiftUI

struct PixelPanel<Content: View>: View {
    var fill: Color = DTheme.surface
    /// nil이면 테두리를 그리지 않는다
    var border: Color? = DTheme.cardEdge
    var borderWidth: CGFloat = 1.5
    var radius: CGFloat = AppRadius.md
    /// 내용이 모서리를 넘지 않게 자른다. 줄 구분선이 끝까지 닿는 목록에 쓴다
    var clipsContent: Bool = false
    /// 오른쪽 아래로 밀린 블록 그림자 — 픽셀 게임 UI의 입체 표현
    var blockShadow: Bool = false
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius) }

    var body: some View {
        ZStack {
            if blockShadow {
                shape.fill(DTheme.purpleDeep).offset(x: 3, y: 3)
            }
            panel
        }
    }

    @ViewBuilder
    private var panel: some View {
        let filled = content()
            .background(shape.fill(fill))
            .overlay(border.map { shape.stroke($0, lineWidth: borderWidth) })
        if clipsContent {
            filled.clipShape(shape)
        } else {
            filled
        }
    }
}

// MARK: - 이미 있는 뷰를 감쌀 때

extension View {
    /// 패딩까지 끝난 뷰 뒤에 패널을 깐다
    func pixelPanel(fill: Color = DTheme.surface,
                    border: Color? = DTheme.cardEdge,
                    borderWidth: CGFloat = 1.5,
                    radius: CGFloat = AppRadius.md,
                    clipsContent: Bool = false,
                    blockShadow: Bool = false) -> some View {
        PixelPanel(fill: fill, border: border, borderWidth: borderWidth,
                   radius: radius, clipsContent: clipsContent, blockShadow: blockShadow) { self }
    }
}

#Preview("PixelPanel") {
    ZStack {
        DTheme.bgDeep.ignoresSafeArea()
        VStack(spacing: AppSpacing.xxl) {
            PixelPanel {
                Text("기본 패널").font(AppFont.body).foregroundColor(DTheme.textSoft)
                    .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.xl)
            }
            PixelPanel(border: nil, radius: AppRadius.lg) {
                Text("테두리 없는 패널").font(AppFont.body).foregroundColor(DTheme.textSoft)
                    .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.xl)
            }
            PixelPanel(fill: DTheme.overlayCard, border: DTheme.purple,
                       radius: AppRadius.lg, blockShadow: true) {
                Text("블록 그림자").font(AppFont.body).foregroundColor(DTheme.textSoft)
                    .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.xl)
            }
        }
        .padding(AppSpacing.xxxl)
    }
}

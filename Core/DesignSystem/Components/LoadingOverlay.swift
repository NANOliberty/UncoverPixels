//
//  LoadingOverlay.swift
//  UncoverYourPixels
//
//  작업이 끝날 때까지 화면을 덮는 표시. 저장·변환·광고 로딩에 쓴다.
//

import SwiftUI

struct LoadingOverlay: View {
    let message: String
    var compact: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: compact ? 12 : 16) {
                ProgressView()
                    .tint(compact ? DTheme.purplePale : DTheme.purpleLight)
                    .scaleEffect(compact ? 1.4 : 1.5)
                Text(message)
                    .font(compact ? AppFont.callout : AppFont.custom(20))
                    .foregroundColor(DTheme.purplePale)
            }
            .padding(compact ? 28 : 32)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(DTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(DTheme.purple, lineWidth: 1.5))
            )
        }
    }
}

#Preview("LoadingOverlay") {
    ZStack {
        DTheme.bg.ignoresSafeArea()
        LoadingOverlay(message: "저장 중...")
    }
}

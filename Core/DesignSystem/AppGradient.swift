//
//  AppGradient.swift
//  UncoverYourPixels
//
//  배경 그라데이션 토큰.
//

import SwiftUI

enum AppGradient {
    static let night     = Color(hex: "#0a0a1a")
    static let nightDeep = Color(hex: "#070614")

    // 보라 축
    static let indigo = Color(hex: "#4B3FBE")
    static let violet = Color(hex: "#7A5CE0")
    static let lilac  = Color(hex: "#A78BFA")
    // 따뜻한 축
    static let rose    = Color(hex: "#E58FB8")
    static let magenta = Color(hex: "#C45FD0")
    // 차가운 축
    static let azure = Color(hex: "#3E7BD8")
    static let teal  = Color(hex: "#43B6C4")

    /// 버튼 등 강조 요소
    static var accent: LinearGradient {
        LinearGradient(colors: [indigo, violet], startPoint: .leading, endPoint: .trailing)
    }
}

/// 화면 전체 배경.
struct AuroraBackground: View {
    enum Palette {
        case nebula   // 남보라 → 보라 → 분홍
        case aurora   // 청록 → 파랑 → 보라
        case dusk     // 자홍 → 보라, 아래쪽이 밝다

        var colors: [Color] {
            switch self {
            case .nebula:
                return [
                    AppGradient.nightDeep, AppGradient.indigo,          AppGradient.nightDeep,
                    AppGradient.violet,    AppGradient.lilac,           AppGradient.magenta.opacity(0.9),
                    AppGradient.nightDeep, AppGradient.rose.opacity(0.8), AppGradient.night,
                ]
            case .aurora:
                return [
                    AppGradient.nightDeep, AppGradient.azure,            AppGradient.nightDeep,
                    AppGradient.teal,      AppGradient.lilac,            AppGradient.violet,
                    AppGradient.night,     AppGradient.indigo.opacity(0.9), AppGradient.nightDeep,
                ]
            case .dusk:
                return [
                    AppGradient.nightDeep, AppGradient.indigo.opacity(0.8), AppGradient.nightDeep,
                    AppGradient.magenta,   AppGradient.violet,              AppGradient.rose,
                    AppGradient.night,     AppGradient.lilac.opacity(0.8),  AppGradient.night,
                ]
            }
        }
    }

    var palette: Palette = .nebula
    var animated: Bool = true
    /// 글자 뒤에서 너무 밝으면 올린다 (0...1)
    var dim: Double = 0.3

    var body: some View {
        ZStack {
            AppGradient.nightDeep

            if animated {
                TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                    mesh(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                mesh(at: 0)
            }

            // 가장자리를 어둡게 눌러 가운데로 시선을 모은다
            RadialGradient(colors: [.clear, AppGradient.nightDeep.opacity(0.75)],
                           center: .center, startRadius: 180, endRadius: 560)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func mesh(at time: TimeInterval) -> some View {
        let a = Float(sin(time * 0.18)) * 0.08
        let b = Float(cos(time * 0.13)) * 0.08

        return MeshGradient(
            width: 3, height: 3,
            points: [
                .init(0.0, 0.0),      .init(0.5 + a, 0.0),      .init(1.0, 0.0),
                .init(0.0, 0.5 - b),  .init(0.5 + b, 0.45 + a), .init(1.0, 0.5 + b),
                .init(0.0, 1.0),      .init(0.5 - a, 1.0),      .init(1.0, 1.0),
            ],
            colors: palette.colors
        )
        .blur(radius: 50)
        .overlay(AppGradient.nightDeep.opacity(dim))
    }
}

#Preview("nebula") { ZStack { AuroraBackground(palette: .nebula); sampleText } }
#Preview("aurora") { ZStack { AuroraBackground(palette: .aurora); sampleText } }
#Preview("dusk")   { ZStack { AuroraBackground(palette: .dusk);   sampleText } }

private var sampleText: some View {
    VStack(spacing: 16) {
        Text("일기에 이름을 적어주세요")
            .font(AppFont.custom(26)).foregroundColor(.white)
        Text("nano\u{2019}s Diary")
            .font(AppFont.custom(18)).foregroundColor(DTheme.purplePale)
    }
}

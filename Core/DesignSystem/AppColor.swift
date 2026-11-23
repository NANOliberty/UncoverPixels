//
//  AppColor.swift
//  UncoverYourPixels
//
//  앱 전체 색 토큰. 뷰에서 Color(hex:)를 직접 쓰지 않고 여기를 거친다.
//

import SwiftUI
import UIKit

enum DTheme {
    // MARK: 배경
    static let bg0     = Color(hex: "#0a0a1a")   // 가장 어두운 배경
    static let bg1     = Color(hex: "#0f0d28")
    static let bg2     = Color(hex: "#1a1530")   // 원형 버튼 등 살짝 뜬 면
    static let surface = Color(hex: "#13112a")   // 카드·입력 필드 배경

    // MARK: 보라 계열
    static let purple      = Color(hex: "#534AB7")   // 주 색 — 버튼 배경, 테두리
    static let purpleLight = Color(hex: "#7F77DD")   // 강조 테두리, 활성 상태
    static let purplePale  = Color(hex: "#AFA9EC")   // 본문 텍스트
    static let purpleDark  = Color(hex: "#3C3489")   // 보조 텍스트, 비활성
    static let purpleDeep  = Color(hex: "#26215C")   // 비활성 테두리, 비활성 버튼 배경

    // MARK: 텍스트
    static let textBright = Color.white
    static let textMid    = purplePale
    static let textDim    = purpleDark

    // MARK: 상태
    static let danger = Color(hex: "#E05C7A")   // 삭제
    static let error  = Color(hex: "#E24B4A")   // 오류 메시지

    // MARK: 플레이 화면
    static let hint        = Color(hex: "#D08937")   // 힌트 버튼
    static let marking     = Color(hex: "#C0445A")   // 마킹 모드
    static let hintBar     = Color(hex: "#0d0b1a")   // 힌트 숫자 줄 배경
    static let hintDone    = Color(hex: "#6B6499")   // 완성된 줄의 힌트 숫자
    static let hintOK      = Color(hex: "#5EC48A")   // 조건을 만족한 힌트 숫자
    static let cellEmpty   = Color(hex: "#1e1c3a")   // 빈 칸
    static let cellInLine  = Color(hex: "#1A4040")   // 완성된 행·열의 칸
    static let surfaceMuted = Color(hex: "#1c1a28")  // 이미 푼 카드

    // MARK: 메인 화면
    static let panel      = Color(hex: "#1a1a2e")   // 말풍선·패널 배경
    static let panelFill  = Color(hex: "#2a2a4a")   // 패널 안 채움
    static let starPale   = Color(hex: "#CECBF6")   // 배경 별

    // MARK: 마스코트 표정 (강조색 / 볼)
    static let mascotExcitedAccent   = Color(hex: "#EF9F27")
    static let mascotThinkingAccent  = Color(hex: "#5DCAA5")
    static let mascotSleepyAccent    = Color(hex: "#85B7EB")
    static let mascotSurprisedAccent = Color(hex: "#F0997B")
    static let mascotHappyCheek      = Color(hex: "#D4537E")
    static let mascotExcitedCheek    = Color(hex: "#D85A30")
    static let mascotThinkingCheek   = Color(hex: "#1D9E75")
    static let mascotSleepyCheek     = Color(hex: "#378ADD")

    // MARK: 온보딩·로그인
    static let textSoft    = Color(hex: "#e8e4ff")   // 온보딩 본문
    static let cardBg      = Color(hex: "#13122a")   // 카드·버튼 배경
    static let cardBgAlt   = Color(hex: "#1a1836")   // 한 단계 밝은 카드
    static let cardEdge    = Color(hex: "#2e2c5a")   // 카드 테두리
    static let googleBlue  = Color(hex: "#4285F4")   // 구글 로고 색

    // MARK: 설정 화면
    static let settingSurface = Color(hex: "#13122a")   // 셀 배경
    static let settingMuted   = Color(hex: "#4a4870")   // 흐린 텍스트
    static let toggleOff      = Color(hex: "#2a2845")   // 토글 꺼짐
    static let toggleOffEdge  = Color(hex: "#3a3860")   // 토글 테두리·화살표
    static let divider        = Color(hex: "#1e1d3a")   // 구분선

    // MARK: Easy 퍼즐 카테고리 강조색
    static let categoryFood        = Color(hex: "#D08937")
    static let categoryDaily       = Color(hex: "#9B8EE0")
    static let categorySea         = Color(hex: "#5EB8D4")
    static let categoryObservation = Color(hex: "#F7C42B")

    // MARK: 배경 그라디언트
    static var bg: LinearGradient {
        LinearGradient(colors: [bg0, bg1, bg2], startPoint: .top, endPoint: .bottom)
    }

    /// 플레이·타일 화면 배경 (기존 리터럴 값을 그대로 옮긴 것)
    static let playBg0 = Color(red: 0.051, green: 0.043, blue: 0.118)
    static let playBg1 = Color(red: 0.082, green: 0.059, blue: 0.188)
    static let playBg2 = Color(red: 0.035, green: 0.027, blue: 0.090)

    static var playBg: LinearGradient {
        LinearGradient(colors: [playBg0, playBg1, playBg2], startPoint: .top, endPoint: .bottom)
    }

    /// 시트 배경
    static let sheetBg = Color(red: 0.04, green: 0.04, blue: 0.10)

    /// 플레이 화면 그라디언트 끝단 / 결과 카드 배경
    static let playBgTail = Color(red: 0.02, green: 0.01, blue: 0.08)
    static let overlayCard = Color(red: 0.08, green: 0.06, blue: 0.18)

    /// 다이어리 상세에서 쓰는 짙은 배경
    static let deep0 = Color(hex: "#0d0b1e")
    static let deep1 = Color(hex: "#130e2e")
    static let deep2 = Color(hex: "#090717")

    static var bgDeep: LinearGradient {
        LinearGradient(colors: [deep0, deep1, deep2], startPoint: .top, endPoint: .bottom)
    }

    /// 표지 카드 배경 / 비활성 네비 버튼 배경
    static let coverTint  = Color(hex: "#12091e")
    static let navInactive = Color(hex: "#0a0612")
}

// MARK: - 내보내기 이미지용 (CoreGraphics는 UIColor를 받는다)

extension UIColor {
    /// 내보낸 이미지의 배경
    static let exportBackground = UIColor(red: 0.05, green: 0.04, blue: 0.1, alpha: 1)
    /// 밝은 그림 위에 찍는 스탬프
    static let exportStampOnLight = UIColor(red: 0.05, green: 0.05, blue: 0.35, alpha: 0.95)
    /// 어두운 그림 위에 찍는 스탬프
    static let exportStampOnDark = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.95)
}

// MARK: - 16진수 색 표기

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

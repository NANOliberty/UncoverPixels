//
//  AppFont.swift
//  UncoverYourPixels
//
//  앱 전체 글꼴 토큰. 폰트 이름 문자열을 뷰에 반복해 쓰지 않는다.
//

import SwiftUI

enum AppFont {
    static let family = "NeoDunggeunmoPro-Regular"

    /// 토큰에 없는 크기가 필요할 때만 쓴다.
    static func custom(_ size: CGFloat) -> Font { .custom(family, size: size) }

    static let display = Font.custom(family, size: 34)   // PUZZLE CLEAR 등 큰 문구
    static let title   = Font.custom(family, size: 26)   // 화면 제목
    static let heading = Font.custom(family, size: 22)   // 섹션 제목, 주요 버튼
    static let body    = Font.custom(family, size: 18)   // 본문, 입력 필드
    static let callout = Font.custom(family, size: 16)   // 보조 버튼
    static let label   = Font.custom(family, size: 15)   // 입력 라벨
    static let caption = Font.custom(family, size: 14)   // 설명 문구
    static let small   = Font.custom(family, size: 13)   // 글자 수, 보조 수치
    static let tiny    = Font.custom(family, size: 11)   // 뱃지

    /// 노노그램 힌트 숫자 — 작고 선명해야 해서 시스템 고정폭을 쓴다
    static let hintNumber = Font.system(size: 10, weight: .bold, design: .monospaced)
}

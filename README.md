<p align="center">
  <img src="docs/icon.png" width="120" alt="Uncover Pixels" />
</p>

<h1 align="center">Uncover Pixels</h1>

<p align="center">사진을 노노그램 퍼즐로 바꿔 풀고, 다 풀면 일기처럼 남기는 iOS 앱</p>

<p align="center">
  <a href="https://apps.apple.com/kr/app/uncoverpixels/id6769139305"><img src="https://img.shields.io/badge/App%20Store-Uncover%20Pixels-0D96F6?logo=apple&logoColor=white" alt="App Store" /></a>
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift" />
  <img src="https://img.shields.io/badge/SwiftUI-iOS%2026-blue" alt="SwiftUI" />
</p>

<p align="center">
  <img src="docs/store-1.jpg" width="150" />
  <img src="docs/store-2.jpg" width="150" />
  <img src="docs/store-3.jpg" width="150" />
  <img src="docs/store-4.jpg" width="150" />
  <img src="docs/store-5.jpg" width="150" />
</p>

> 전체 소스는 비공개. 이 저장소에는 퍼즐 규칙·이미지 파이프라인·플레이 상태 관리 등 핵심 모듈 4개와 설계 설명만 공개. 코드의 재배포 및 상업적 이용 불가.
> 1인 개발(기획·디자인·개발·운영), 2026.04 ~ 운영 중. 개발에 Claude Code 적극 활용.

## 무엇을 하는 앱인가

1. 사진 선택
2. 120×120 픽셀로 축소 후 밝기 기준 흑백 노노그램 도안 생성
3. 도안을 15×15(노말, 64타일) 또는 20×20(하드, 36타일)로 잘라 타일 하나씩 풀기
4. 타일을 풀 때마다 그 부분의 원래 색이 드러나고, 전부 풀면 사진 완성
5. 제목과 한 줄 일기를 붙여 다이어리에 저장, 날짜·제목 스탬프를 찍어 사진 앱으로 내보내기

노노그램을 좋아하는 친구와 추억 기록을 좋아하는 내가 같이 쓰려고 만든 앱.

## 화면

<table>
<tr>
<td align="center"><img src="docs/ipad-home.jpg" width="260" /><br/>홈</td>
<td align="center"><img src="docs/ipad-play.jpg" width="260" /><br/>플레이 — 힌트 · 목숨 · 진행률</td>
<td align="center"><img src="docs/ipad-diary.jpg" width="260" /><br/>다이어리 표지</td>
</tr>
</table>

<table>
<tr>
<td width="340"><img src="docs/demo-cascade.gif" width="320" /></td>
<td valign="top">
<b>타일 완성 → 캐스케이드</b><br/><br/>
마지막 칸을 채우면 대각선 순서(row+col)로 셀이 뒤집히며 흑백 도안이 원래 색으로 바뀜.
목숨·진행률은 상단, 힌트는 우하단(리워드 광고 또는 광고 제거 구매 시 즉시).
</td>
</tr>
<tr>
<td width="340"><img src="docs/export-samples.jpg" width="200" /></td>
<td valign="top">
<b>완성 후 내보내기</b><br/><br/>
타일을 전부 풀면 원본 사진이 드러나고, 날짜와 한 줄 제목을 스탬프로 찍어 사진 앱에 저장.
</td>
</tr>
</table>

## 기술 스택

| 영역 | 사용 |
|---|---|
| UI | SwiftUI (iOS 26) |
| 이미지 처리 | Core Image (CIUnsharpMask·CIColorControls), CGContext 픽셀 버퍼 |
| 인증 | Firebase Auth — 게스트(익명) → Google / Apple 계정 연결 |
| 저장 | Firestore (PersistentCache로 오프라인 열람·로컬 우선 쓰기) |
| 수익화 | AdMob 리워드 광고(힌트·이어하기), StoreKit 2 광고 제거 상품 |
| 기타 | Crashlytics, PhotosUI, 햅틱 |

## 이 저장소의 구성

```
Core/
├── Models/NonogramModel.swift        퍼즐 규칙 — 힌트 계산, 탭/마킹/목숨, 완성 판정
├── Services/ImagePixelizer.swift     사진 → 노노그램 변환 파이프라인
└── ViewModels/PlayViewModel.swift    플레이 상태, 힌트·이어하기, 진행 저장/복원
Features/
└── Nonogram/NonogramGridView.swift   그리드 뷰 — 축 고정 드래그 채우기, 커서, 캐스케이드
docs/                                 스크린샷
```

전체 앱 구조(비공개 부분 포함):

```
UncoverYourPixels/
├── App/                     진입점, Firebase·AdMob 초기화
├── Core/Models, Services, ViewModels
├── Features/Onboarding, Play, Nonogram, Diary, Main, Settings
├── Resources/               에셋, 색상, Easy 공식 퍼즐 42개(4카테고리)
└── Shared/                  폰트, 공통 컴포넌트
```

## 핵심 로직

### 사진 → 퍼즐 (`ImagePixelizer`)

- EXIF 회전 정규화 → 언샤프 마스크·대비 1.3으로 윤곽 강조 → 120×120 리사이즈
- 밝기(`0.299R + 0.587G + 0.114B`) 임계값으로 흑백화. 사진마다 밝기가 달라 고정 임계값으로는 너무 비거나 꽉 차므로, 채움 비율 30~60%에 들어올 때까지 임계값을 ±0.07씩 최대 6회 조정
- 타일로 자른 뒤 밀도 18% 미만·82% 초과이거나 빈 행/열이 2개를 넘는 타일은 퍼즐로 성립하지 않으므로 blob 성장 방식의 랜덤 도안으로 교체(각 행·열 최소 1칸 보장)
- 채도 0.2 이상 픽셀을 16단계 버킷으로 묶어 가장 많은 버킷의 평균색을 대표색으로 추출 → 다이어리 배경에 사용

### 플레이 (`NonogramModel`, `PlayViewModel`, `NonogramGridView`)

- 힌트 자동 계산, 탭/마킹/목숨(노말 5·하드 8), 행·열·힌트 블록 단위 완성 판정
- 드래그 채우기: 첫 4pt 이동으로 가로/세로 축 고정, 시작 칸~현재 칸을 범위로 채움. 첫 오답에서 중단해 목숨 연속 차감 방지
- 타일별 진행 상태를 UserDefaults에 저장 → 중간에 나가도 이어서 풀기 가능
- 완성 시 대각선 순서(row+col)로 셀이 뒤집히는 캐스케이드 연출

### 저장·오프라인 (`FirestoreService`)

- 사진 한 장 = `users/{uid}/diaries/{id}` 문서 하나. 타일별 흑백·컬러 픽셀을 함께 저장
- 타일 완성·제목 수정 같은 UI 경로의 쓰기는 `await` 없이 호출. Firestore가 즉시 로컬에 기록하고 네트워크 복구 시 동기화하므로 오프라인에서도 화면이 멈추지 않음
- 빈 문자열은 Firestore 경로로 쓸 수 없어 런타임 크래시 → 모든 경로에 가드

### 광고 (`AdService`)

- 리워드 광고 로드에 7초 타임아웃. 로드·표시 실패 시 보상 그대로 지급(광고 때문에 게임이 막히지 않도록), 중복 지급은 플래그로 차단
- 광고 제거 상품 구매 시 광고 없이 즉시 보상

## 타임라인

| 시기 | 내용 |
|---|---|
| 2026.03~04 | 기획·디자인, 노노그램 코어, 이미지 파이프라인, 다이어리, 온보딩 |
| 2026.05.19 | App Store 출시 |
| 2026.05 | iPad 배경색·그리드 비율 수정, 갤러리 대표색 캐시, 리워드 광고·광고 제거 상품 |
| 2026.09 | 오프라인 쓰기 멈춤, 게스트 로그인 실패 크래시, 드래그 목숨 연속 차감, 타일 진행 저장 — 네 건 수정 |

## 빌드에 대해

이 저장소만으로는 빌드 불가. 공개된 파일은 `UIKit`·`SwiftUI`·`CoreImage`만 사용하며, `PlayViewModel`이 참조하는 `AdService`(광고)와 `NonogramGridView`의 `Color(hex:)` 확장만 비공개 모듈에 있음. 전체 소스 열람이 필요하면 연락 바람.

## 알고 있는 한계

- 단위 테스트 없음. 노노그램 규칙과 픽셀화는 순수 함수라 붙이기 쉬운 편
- 광고 실패 시 보상 지급 정책은 비행기 모드로 힌트를 무한히 받을 수 있는 구조. 캐주얼 게임이라 감수
- 다이어리 문서에 컬러 픽셀을 통째로 넣어 문서 크기가 큼. 이미지를 Storage에 두고 참조하는 쪽이 맞음
- 출시 후에 git을 시작해 초기 개발 이력이 커밋으로 남아 있지 않음

## 폰트

- [VT323](https://fonts.google.com/specimen/VT323) — SIL Open Font License
- [Neo둥근모 Pro](https://neodgm.dalgona.dev/) — SIL Open Font License

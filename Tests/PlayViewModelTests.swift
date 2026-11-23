//
//  PlayViewModelTests.swift
//  UncoverYourPixelsTests
//
//  진행 상황 저장과 복원. 실제로 났던 버그 세 건을 고정한다.
//

import Testing
import Foundation
@testable import UncoverYourPixels

@MainActor
struct PlayViewModelTests {

    private func crossSolution() -> [[Bool]] {
        (0..<5).map { row in (0..<5).map { col in row == 2 || col == 2 } }
    }

    private func makePuzzle() -> NonogramPuzzle {
        NonogramPuzzle(size: 5, solution: crossSolution())
    }

    /// 테스트마다 새 저장소를 쓴다. 실제 앱 설정을 건드리지 않는다
    private func makeStore(_ name: String = UUID().uuidString) -> UserDefaults {
        UserDefaults(suiteName: name)!
    }

    // MARK: - 저장과 복원

    @Test func 저장하고_나가면_채운_칸이_남는다() {
        let store = makeStore()
        let key = "tile_0_0"

        let first = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        _ = first.puzzle.tap(row: 2, col: 0)
        _ = first.puzzle.tap(row: 2, col: 1)
        first.saveProgress()

        let restored = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)

        #expect(restored.puzzle.cells[2][0] == .filled)
        #expect(restored.puzzle.cells[2][1] == .filled)
        #expect(restored.puzzle.cells[0][0] == .empty)
    }

    /// 목숨을 저장하지 않던 시절에는 나갔다 들어오는 것만으로 목숨이 꽉 찼다
    @Test func 저장하고_나가면_줄어든_목숨도_그대로다() {
        let store = makeStore()
        let key = "tile_1_1"

        let first = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        _ = first.puzzle.tap(row: 0, col: 0)   // 오답
        _ = first.puzzle.tap(row: 0, col: 1)   // 오답
        #expect(first.puzzle.lives == 3)
        first.saveProgress()

        let restored = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)

        #expect(restored.puzzle.lives == 3)
    }

    @Test func 저장한_적이_없으면_목숨은_최대치로_시작한다() {
        let store = makeStore()
        let model = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: "tile_2_2", store: store)

        #expect(model.puzzle.lives == 5)
    }

    @Test func 저장된_목숨이_난이도_최대치를_넘지_않는다() {
        let store = makeStore()
        let key = "tile_3_3"

        // 하드(8개)로 저장한 뒤 노말(5개)로 열어도 5를 넘지 않아야 한다
        let hard = PlayViewModel(puzzle: makePuzzle(), lives: 8, saveKey: key, store: store)
        hard.saveProgress()

        let normal = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)

        #expect(normal.puzzle.lives == 5)
    }

    @Test func 저장을_지우면_처음부터_시작한다() {
        let store = makeStore()
        let key = "tile_4_4"

        let first = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        _ = first.puzzle.tap(row: 2, col: 0)
        _ = first.puzzle.tap(row: 0, col: 0)   // 오답 하나
        first.saveProgress()
        first.clearSavedProgress()

        let restored = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)

        #expect(restored.puzzle.cells[2][0] == .empty)
        #expect(restored.puzzle.lives == 5)
    }

    @Test func 저장_키가_없으면_아무것도_남지_않는다() {
        let store = makeStore()
        let model = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: nil, store: store)
        _ = model.puzzle.tap(row: 2, col: 0)
        model.saveProgress()

        let saved = store.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("progress_") || $0.hasPrefix("lives_") || $0.hasPrefix("hint_used_")
        }
        #expect(saved.isEmpty)
    }

    // MARK: - 복원 후 완성 처리

    /// 다 푼 상태로 복원되면 완성으로 잡아야 한다.
    /// 이게 없던 동안에는 모든 칸이 채워진 채 열려 아무것도 누를 수 없었다
    @Test func 다_푼_상태로_복원하면_완성으로_잡힌다() {
        let store = makeStore()
        let key = "tile_5_5"
        let solution = crossSolution()

        let first = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        for row in 0..<5 {
            for col in 0..<5 where solution[row][col] {
                _ = first.puzzle.tap(row: row, col: col)
            }
        }
        first.saveProgress()

        let restored = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        restored.puzzle.isSolved = false            // 저장에는 완성 여부가 들어가지 않는다
        restored.checkRestoredCompletion()

        #expect(restored.puzzle.isSolved)
    }

    @Test func 덜_푼_상태로_복원하면_완성이_아니다() {
        let store = makeStore()
        let key = "tile_6_6"

        let first = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        _ = first.puzzle.tap(row: 2, col: 0)
        first.saveProgress()

        let restored = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        restored.checkRestoredCompletion()

        #expect(restored.puzzle.isSolved == false)
    }

    // MARK: - 힌트

    /// 완성 직후 연출이 도는 동안에도 힌트 버튼을 누를 수 있었고,
    /// 채울 칸이 없는데 무료 힌트만 소모됐다
    @Test func 완성된_퍼즐에서는_힌트가_소모되지_않는다() {
        let store = makeStore()
        let model = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: "tile_7_7", store: store)
        let solution = crossSolution()
        for row in 0..<5 {
            for col in 0..<5 where solution[row][col] {
                _ = model.puzzle.tap(row: row, col: col)
            }
        }
        #expect(model.puzzle.isSolved)

        model.useHint()

        #expect(model.hintUsed == false)
    }

    @Test func 무료_힌트를_쓰면_다시_열어도_쓴_것으로_남는다() {
        let store = makeStore()
        let key = "tile_8_8"

        let first = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)
        first.useHint()
        #expect(first.hintUsed)

        let reopened = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: key, store: store)

        #expect(reopened.hintUsed)
    }

    // MARK: - 초기화

    @Test func 처음부터_다시_하면_칸과_목숨이_돌아온다() {
        let store = makeStore()
        let model = PlayViewModel(puzzle: makePuzzle(), lives: 5, saveKey: "tile_9_9", store: store)
        _ = model.puzzle.tap(row: 2, col: 0)
        _ = model.puzzle.tap(row: 0, col: 0)
        model.saveProgress()

        model.resetPuzzle()

        #expect(model.puzzle.cells[2][0] == .empty)
        #expect(model.puzzle.lives == 5)
        #expect(model.hintUsed == false)
        #expect(store.object(forKey: "progress_tile_9_9") == nil)
    }
}

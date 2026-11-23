//
//  NonogramPuzzleTests.swift
//  UncoverYourPixelsTests
//
//  퍼즐 규칙 — 힌트 계산, 탭 결과, 완성 판정
//

import Testing
@testable import UncoverYourPixels

@MainActor
struct NonogramPuzzleTests {

    /// 5×5 도안. 가운데 십자 모양
    ///
    ///   . . X . .
    ///   . . X . .
    ///   X X X X X
    ///   . . X . .
    ///   . . X . .
    private func crossSolution() -> [[Bool]] {
        (0..<5).map { row in (0..<5).map { col in row == 2 || col == 2 } }
    }

    private func makePuzzle(lives: Int = 3) -> NonogramPuzzle {
        var puzzle = NonogramPuzzle(size: 5, solution: crossSolution())
        puzzle.lives = lives
        return puzzle
    }

    // MARK: - 힌트 계산

    @Test func 행_힌트는_연속한_칸의_길이로_계산된다() {
        let hints = NonogramPuzzle.calculateHints(for: crossSolution(), isRow: true)

        #expect(hints[0] == [1])   // 가운데 한 칸
        #expect(hints[2] == [5])   // 한 줄 전체
        #expect(hints[4] == [1])
    }

    @Test func 열_힌트도_같은_규칙을_따른다() {
        let hints = NonogramPuzzle.calculateHints(for: crossSolution(), isRow: false)

        #expect(hints[0] == [1])
        #expect(hints[2] == [5])
    }

    @Test func 빈_줄의_힌트는_0이다() {
        let empty = Array(repeating: Array(repeating: false, count: 3), count: 3)
        let hints = NonogramPuzzle.calculateHints(for: empty, isRow: true)

        #expect(hints[0] == [0])
    }

    // MARK: - 탭

    @Test func 정답_칸을_누르면_채워진다() {
        var puzzle = makePuzzle()
        let result = puzzle.tap(row: 2, col: 0)

        guard case .correct = result else {
            Issue.record("정답 칸인데 \(result)가 나왔다")
            return
        }
        #expect(puzzle.cells[2][0] == .filled)
        #expect(puzzle.lives == 3)
    }

    @Test func 오답_칸을_누르면_목숨이_하나_줄고_X로_표시된다() {
        var puzzle = makePuzzle()
        let result = puzzle.tap(row: 0, col: 0)

        guard case .wrong(let livesLeft) = result else {
            Issue.record("오답 칸인데 \(result)가 나왔다")
            return
        }
        #expect(livesLeft == 2)
        #expect(puzzle.lives == 2)
        #expect(puzzle.cells[0][0] == .marked)
    }

    @Test func 이미_누른_칸은_무시된다() {
        var puzzle = makePuzzle()
        _ = puzzle.tap(row: 2, col: 0)
        let again = puzzle.tap(row: 2, col: 0)

        guard case .ignored = again else {
            Issue.record("같은 칸을 다시 눌렀는데 \(again)가 나왔다")
            return
        }
        #expect(puzzle.lives == 3)
    }

    @Test func 목숨을_모두_잃으면_실패한다() {
        var puzzle = makePuzzle(lives: 2)
        _ = puzzle.tap(row: 0, col: 0)
        let result = puzzle.tap(row: 0, col: 1)

        guard case .failed = result else {
            Issue.record("목숨이 0인데 \(result)가 나왔다")
            return
        }
        #expect(puzzle.lives == 0)
    }

    @Test func 목숨이_없으면_더_누를_수_없다() {
        var puzzle = makePuzzle(lives: 1)
        _ = puzzle.tap(row: 0, col: 0)   // 실패

        let result = puzzle.tap(row: 2, col: 0)   // 정답 칸이지만 이미 끝났다
        guard case .ignored = result else {
            Issue.record("실패 후인데 \(result)가 나왔다")
            return
        }
    }

    // MARK: - 완성

    @Test func 정답_칸을_모두_채우면_완성된다() {
        var puzzle = makePuzzle()
        let solution = crossSolution()
        var last: TapResult = .ignored

        for row in 0..<5 {
            for col in 0..<5 where solution[row][col] {
                last = puzzle.tap(row: row, col: col)
            }
        }

        guard case .solved = last else {
            Issue.record("마지막 칸을 채웠는데 \(last)가 나왔다")
            return
        }
        #expect(puzzle.isSolved)
    }

    @Test func 오답_칸을_비워둬도_완성으로_친다() {
        // X 표시를 하지 않아도 정답 칸만 다 채우면 끝난다
        var puzzle = makePuzzle()
        let solution = crossSolution()
        for row in 0..<5 {
            for col in 0..<5 where solution[row][col] {
                _ = puzzle.tap(row: row, col: col)
            }
        }
        #expect(puzzle.checkSolved())
    }

    @Test func 한_줄을_다_채우면_그_줄이_완성으로_잡힌다() {
        var puzzle = makePuzzle()
        #expect(puzzle.isRowComplete(2) == false)

        for col in 0..<5 { _ = puzzle.tap(row: 2, col: col) }

        #expect(puzzle.isRowComplete(2))
        #expect(puzzle.isColComplete(2) == false)   // 세로는 아직 남았다
    }

    // MARK: - 힌트 공개

    @Test func 힌트는_비어_있는_정답_칸만_채운다() {
        var puzzle = makePuzzle()
        _ = puzzle.tap(row: 2, col: 0)

        let revealed = puzzle.revealRandomCells(count: 3)

        #expect(revealed.count == 3)
        for (row, col) in revealed {
            #expect(crossSolution()[row][col])          // 정답 칸이어야 한다
            #expect(puzzle.cells[row][col] == .filled)
        }
    }

    @Test func 힌트로_마지막_칸이_채워지면_완성_처리된다() {
        var puzzle = makePuzzle()
        let solution = crossSolution()
        let cells = (0..<5).flatMap { r in (0..<5).map { c in (r, c) } }
        let answers = cells.filter { solution[$0.0][$0.1] }

        // 마지막 한 칸만 남기고 채운다
        for (row, col) in answers.dropLast() { _ = puzzle.tap(row: row, col: col) }
        #expect(puzzle.isSolved == false)

        _ = puzzle.revealRandomCells(count: 1)

        #expect(puzzle.isSolved)
    }
}

//
//  NonogramModel.swift
//  UncoverYourPixels
//

import Foundation
import SwiftUI

enum CellState {
    case empty
    case filled
    case marked
}

struct NonogramPuzzle {
    let id: UUID
    let size: Int
    var cells: [[CellState]]
    let solution: [[Bool]]
    let rowHints: [[Int]]
    let colHints: [[Int]]
    var colorGrid: [[Color]]? = nil
    var lives: Int = 3
    var isSolved: Bool = false

    init(id: UUID = UUID(), size: Int, solution: [[Bool]], colorGrid: [[Color]]? = nil) {
        self.id = id
        self.size = size
        self.solution = solution
        self.colorGrid = colorGrid
        self.cells = Array(repeating: Array(repeating: .empty, count: size), count: size)
        self.rowHints = NonogramPuzzle.calculateHints(for: solution, isRow: true)
        self.colHints = NonogramPuzzle.calculateHints(for: solution, isRow: false)
    }

    static func calculateHints(for solution: [[Bool]], isRow: Bool) -> [[Int]] {
        let count = solution.count
        var hints: [[Int]] = []
        for i in 0..<count {
            let line: [Bool] = isRow ? solution[i] : (0..<count).map { solution[$0][i] }
            var groupHints: [Int] = []
            var current = 0
            for cell in line {
                if cell { current += 1 }
                else if current > 0 { groupHints.append(current); current = 0 }
            }
            if current > 0 { groupHints.append(current) }
            if groupHints.isEmpty { groupHints = [0] }
            hints.append(groupHints)
        }
        return hints
    }
}

enum Difficulty {
    case easy, normal, hard
    var gridSize: Int {
        switch self { case .easy: return 10; case .normal: return 15; case .hard: return 20 }
    }
}

// MARK: - 플레이 로직
extension NonogramPuzzle {

    mutating func tap(row: Int, col: Int) -> TapResult {
        guard !isSolved && lives > 0 else { return .ignored }
        guard cells[row][col] == .empty else { return .ignored }

        if solution[row][col] {
            cells[row][col] = .filled
            if checkSolved() { isSolved = true; return .solved }
            return .correct
        } else {
            cells[row][col] = .marked
            lives -= 1
            if lives == 0 { return .failed }
            return .wrong(livesLeft: lives)
        }
    }

    mutating func mark(row: Int, col: Int) {
        guard cells[row][col] == .empty else { return }
        cells[row][col] = .marked
    }

    // 마킹 토글 — empty → marked, marked → empty
    mutating func toggleMark(row: Int, col: Int) {
        switch cells[row][col] {
        case .empty:  cells[row][col] = .marked
        case .marked: cells[row][col] = .empty
        case .filled: break
        }
    }

    mutating func reset(row: Int, col: Int) { cells[row][col] = .empty }

    mutating func restoreLives(to count: Int) { lives = count }

    // MARK: - 힌트: 랜덤 N개 정답 공개
    @discardableResult
    mutating func revealRandomCells(count: Int) -> [(Int, Int)] {
        var candidates: [(Int, Int)] = []
        for r in 0..<size {
            for c in 0..<size {
                if solution[r][c] && cells[r][c] == .empty { candidates.append((r, c)) }
            }
        }
        let toReveal = Array(candidates.shuffled().prefix(count))
        for (r, c) in toReveal { cells[r][c] = .filled }
        if checkSolved() { isSolved = true }
        return toReveal
    }

    // MARK: - 완성 체크 (internal)
    func checkSolved() -> Bool {
        for row in 0..<size {
            for col in 0..<size {
                if solution[row][col] && cells[row][col] != .filled { return false }
            }
        }
        return true
    }

    // MARK: - 행/열 완성 여부
    func isRowComplete(_ row: Int) -> Bool {
        let hasAnyCells = solution[row].contains(true)
        guard hasAnyCells else { return false }
        return !solution[row].indices.contains(where: { solution[row][$0] && cells[row][$0] != .filled })
    }

    func isColComplete(_ col: Int) -> Bool {
        let hasAnyCells = (0..<size).contains(where: { solution[$0][col] })
        guard hasAnyCells else { return false }
        return !(0..<size).contains(where: { solution[$0][col] && cells[$0][col] != .filled })
    }

    // MARK: - 부분 힌트 완성 여부
    // 행의 각 힌트 블록이 채워졌는지 (hint index별)
    func rowHintBlocks(_ row: Int) -> [[Int]] {
        var blocks: [[Int]] = []
        var current: [Int] = []
        for col in 0..<size {
            if solution[row][col] { current.append(col) }
            else if !current.isEmpty { blocks.append(current); current = [] }
        }
        if !current.isEmpty { blocks.append(current) }
        return blocks
    }

    func colHintBlocks(_ col: Int) -> [[Int]] {
        var blocks: [[Int]] = []
        var current: [Int] = []
        for row in 0..<size {
            if solution[row][col] { current.append(row) }
            else if !current.isEmpty { blocks.append(current); current = [] }
        }
        if !current.isEmpty { blocks.append(current) }
        return blocks
    }

    func isRowHintSatisfied(_ row: Int, at idx: Int) -> Bool {
        let blocks = rowHintBlocks(row)
        guard idx < blocks.count else { return false }
        return blocks[idx].allSatisfy { cells[row][$0] == .filled }
    }

    func isColHintSatisfied(_ col: Int, at idx: Int) -> Bool {
        let blocks = colHintBlocks(col)
        guard idx < blocks.count else { return false }
        return blocks[idx].allSatisfy { cells[$0][col] == .filled }
    }
}

enum TapResult {
    case correct
    case wrong(livesLeft: Int)
    case solved
    case failed
    case ignored
}

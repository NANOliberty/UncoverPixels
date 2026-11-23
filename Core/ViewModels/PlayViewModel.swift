//
//  PlayViewModel.swift
//  UncoverYourPixels
//

import SwiftUI
import Combine

class PlayViewModel: ObservableObject {
    @AppStorage("dragFill") var dragFill = true
    @Published var puzzle: NonogramPuzzle
    @Published var lastResult: TapResult = .ignored
    @Published var showFailAlert = false
    @Published var showSolvedAnimation = false
    @Published var cascadeStep: Int = -1

    @Published var isMarkingMode: Bool = false

    @Published var cursorRow: Int = 0
    @Published var cursorCol: Int = 0
    @Published var cursorVisible: Bool = false

    private var lastTouchedRow: Int = 0
    private var lastTouchedCol: Int = 0

    @Published var hintUsed: Bool = false
    @Published var isAdLoading: Bool = false  // 광고 로딩 중 표시용

    // MARK: - 광고 보상 중복 지급 방지 플래그
    private var hintRewardClaimed = false
    private var continueRewardClaimed = false

    private(set) var maxLives: Int
    let saveKey: String?

    // 클리어 연출 작업 — 리셋/화면 종료 시 취소해야 한다
    private var cascadeTask: Task<Void, Never>?

    init(puzzle: NonogramPuzzle, lives: Int? = nil, saveKey: String? = nil) {
        let resolvedLives = lives ?? puzzle.lives
        self.maxLives = resolvedLives
        self.saveKey = saveKey
        _hintUsed = Published(initialValue:
            saveKey.map { UserDefaults.standard.bool(forKey: "hint_used_\($0)") } ?? false
        )
        var mutablePuzzle = puzzle
        mutablePuzzle.lives = resolvedLives
        if let key = saveKey,
           let saved = UserDefaults.standard.array(forKey: "progress_\(key)") as? [Int],
           saved.count == puzzle.size * puzzle.size {
            for row in 0..<puzzle.size {
                for col in 0..<puzzle.size {
                    switch saved[row * puzzle.size + col] {
                    case 1: mutablePuzzle.cells[row][col] = .filled
                    case 2: mutablePuzzle.cells[row][col] = .marked
                    default: mutablePuzzle.cells[row][col] = .empty
                    }
                }
            }
            // 나간 시점의 목숨을 그대로 이어받는다. 저장하지 않으면 나갔다
            // 들어오는 것만으로 목숨이 채워져 광고 보상이 의미를 잃는다.
            if let savedLives = UserDefaults.standard.object(forKey: "lives_\(key)") as? Int,
               savedLives > 0 {
                mutablePuzzle.lives = min(savedLives, resolvedLives)
            }
        }
        self.puzzle = mutablePuzzle

        // 퍼즐을 푸는 동안에는 배경음악이 물러난다.
        // 화면의 onAppear/onDisappear에 걸면 광고가 뜰 때도 퇴장으로 잡혀
        // 음악이 다시 올라온다.
        Task { @MainActor in BGMPlayer.shared.suspend(.puzzle) }
    }

    deinit {
        Task { @MainActor in BGMPlayer.shared.resume(.puzzle) }
    }

    /// 저장된 진행 상황을 복원했을 때 이미 완성된 상태면 완성 처리
    func checkRestoredCompletion() {
        guard !puzzle.isSolved, puzzle.checkSolved() else { return }
        puzzle.isSolved = true
        clearSavedProgress()
        startCascade()
    }

    func tap(row: Int, col: Int) {
        if puzzle.isRowComplete(row) || puzzle.isColComplete(col) { return }
        handleTapResult(puzzle.tap(row: row, col: col))
    }

    func toggleMarkCell(row: Int, col: Int, shouldMark: Bool) {
        if shouldMark {
            guard puzzle.cells[row][col] == .empty else { return }
            puzzle.cells[row][col] = .marked
        } else {
            guard puzzle.cells[row][col] == .marked else { return }
            puzzle.cells[row][col] = .empty
        }
        HapticManager.light()
    }

    func updateLastTouched(row: Int, col: Int) {
        lastTouchedRow = row
        lastTouchedCol = col
    }

    func hideCursor() { cursorVisible = false }

    enum CursorDirection { case up, down, left, right }

    func moveCursor(_ direction: CursorDirection) {
        if !cursorVisible {
            cursorRow = lastTouchedRow
            cursorCol = lastTouchedCol
        }
        cursorVisible = true
        switch direction {
        case .up:    cursorRow = max(0, cursorRow - 1)
        case .down:  cursorRow = min(puzzle.size - 1, cursorRow + 1)
        case .left:  cursorCol = max(0, cursorCol - 1)
        case .right: cursorCol = min(puzzle.size - 1, cursorCol + 1)
        }
        HapticManager.light()
    }

    func activateFillMode() {
        isMarkingMode = false
        guard cursorVisible else { return }
        handleTapResult(puzzle.tap(row: cursorRow, col: cursorCol))
    }

    func activateMarkMode() {
        isMarkingMode = true
        guard cursorVisible else { return }
        puzzle.toggleMark(row: cursorRow, col: cursorCol)
        HapticManager.light()
    }

    // MARK: - 힌트
    func useHint() {
        // 클리어 직후 연출 중에는 힌트가 효과 없이 소모된다
        guard !puzzle.isSolved else { return }
        if hintUsed {
            // 무료 힌트 소진 → 광고 보고 추가 힌트
            isAdLoading = true
            hintRewardClaimed = false

            // 8초 안전장치 - AdService 7초 타임아웃이 작동 안 할 경우 대비
            let timeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                guard !Task.isCancelled, let self else { return }
                if self.isAdLoading {
                    print("⚠️ ViewModel 강제 타임아웃 - 힌트")
                    self.isAdLoading = false
                    if !self.hintRewardClaimed {
                        self.hintRewardClaimed = true
                        self.useHintAfterAd()
                    }
                }
            }

            AdService.shared.loadAndShow(type: .hint) { [weak self] in
                guard let self, !self.hintRewardClaimed else { return }
                self.hintRewardClaimed = true
                self.useHintAfterAd()
            } onDismissed: { [weak self] in
                timeoutTask.cancel()
                self?.isAdLoading = false
            }
            return
        }
        // 무료 힌트 사용
        let revealed = puzzle.revealRandomCells(count: 3)
        if !revealed.isEmpty { HapticManager.success() }
        hintUsed = true
        if let key = saveKey { UserDefaults.standard.set(true, forKey: "hint_used_\(key)") }
        if puzzle.isSolved { clearSavedProgress(); startCascade() }
    }

    func useHintAfterAd() {
        let revealed = puzzle.revealRandomCells(count: 3)
        if !revealed.isEmpty { HapticManager.success() }
        if puzzle.isSolved { startCascade() }
    }

    func saveProgress() {
        guard let key = saveKey else { return }
        let encoded = puzzle.cells.flatMap { $0 }.map { state -> Int in
            switch state { case .empty: return 0; case .filled: return 1; case .marked: return 2 }
        }
        UserDefaults.standard.set(encoded, forKey: "progress_\(key)")
        UserDefaults.standard.set(puzzle.lives, forKey: "lives_\(key)")
        UserDefaults.standard.synchronize()
    }

    func clearSavedProgress() {
        guard let key = saveKey else { return }
        UserDefaults.standard.removeObject(forKey: "progress_\(key)")
        UserDefaults.standard.removeObject(forKey: "lives_\(key)")
        UserDefaults.standard.removeObject(forKey: "hint_used_\(key)")
    }

    func resetPuzzle() {
        cancelCascade()
        for row in 0..<puzzle.size {
            for col in 0..<puzzle.size { puzzle.cells[row][col] = .empty }
        }
        puzzle.lives = maxLives
        puzzle.isSolved = false
        cascadeStep = -1
        showSolvedAnimation = false
        showFailAlert = false
        hintUsed = false
        isMarkingMode = false
        cursorVisible = false
        lastTouchedRow = 0
        lastTouchedCol = 0
        clearSavedProgress()
    }

    private func handleTapResult(_ result: TapResult) {
        lastResult = result
        switch result {
        case .correct: HapticManager.success()
        case .wrong:   HapticManager.error()
        case .solved:
            HapticManager.success()
            clearSavedProgress()
            startCascade()
        case .failed:
            HapticManager.error()
            showFailAlert = true
        case .ignored: break
        }
    }

    private func startCascade() {
        cascadeTask?.cancel()
        let maxStep = (puzzle.size - 1) * 2
        cascadeTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for step in 0...maxStep {
                withAnimation(.none) { self.cascadeStep = step }
                do { try await Task.sleep(nanoseconds: 60_000_000) } catch { return }
            }
            do { try await Task.sleep(nanoseconds: 400_000_000) } catch { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { self.showSolvedAnimation = true }
        }
    }

    // 화면을 벗어날 때 예약된 연출을 정리한다
    func cancelCascade() {
        cascadeTask?.cancel()
        cascadeTask = nil
    }

    // MARK: - 실패 후 광고 보고 계속하기
    func restoreAfterAd() {
        isAdLoading = true
        continueRewardClaimed = false

        // 8초 안전장치 - AdService 7초 타임아웃이 작동 안 할 경우 대비
        let timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            guard !Task.isCancelled, let self else { return }
            if self.isAdLoading {
                print("⚠️ ViewModel 강제 타임아웃 - 이어하기")
                self.isAdLoading = false
                if !self.continueRewardClaimed {
                    self.continueRewardClaimed = true
                    self.puzzle.restoreLives(to: self.maxLives)
                    self.saveProgress()
                    self.showFailAlert = false
                }
            }
        }

        AdService.shared.loadAndShow(type: .continueGame) { [weak self] in
            guard let self, !self.continueRewardClaimed else { return }
            self.continueRewardClaimed = true
            self.puzzle.restoreLives(to: self.maxLives)
            self.saveProgress()
            self.showFailAlert = false
        } onDismissed: { [weak self] in
            timeoutTask.cancel()
            self?.isAdLoading = false
        }
    }

    var progress: Double {
        let total = puzzle.solution.flatMap { $0 }.filter { $0 }.count
        let filled = puzzle.cells.flatMap { $0 }.filter { $0 == .filled }.count
        guard total > 0 else { return 0 }
        return Double(filled) / Double(total)
    }

    var lives: Int { puzzle.lives }
}

// MARK: - 햅틱
struct HapticManager {
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true
    }
    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    static func light() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

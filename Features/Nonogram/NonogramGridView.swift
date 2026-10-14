//
//  NonogramGridView.swift
//  UncoverYourPixels
//

import SwiftUI

private enum DragAxis { case horizontal, vertical }

struct NonogramGridView: View {
    let puzzle: NonogramPuzzle
    let onTap: (Int, Int) -> Void
    var onMarkToggle: ((Int, Int, Bool) -> Void)? = nil
    var onDragStarted: (() -> Void)? = nil
    var onLastCell: ((Int, Int) -> Void)? = nil
    var isMarkingMode: Bool = false
    var cascadeStep: Int = -1
    var cursorRow: Int = -1
    var cursorCol: Int = -1
    var cursorVisible: Bool = false

    @AppStorage("showXMark")     private var showXMark = true
    @AppStorage("dragFill")      private var dragFillEnabled = true
    @AppStorage("showDragCount") private var showDragCount = true

    @State private var dragStartCell: (Int, Int)? = nil
    @State private var lockedAxis: DragAxis? = nil
    @State private var pendingCells: Set<String> = []
    @State private var dragFilling: Bool = true
    @State private var markDragging: Bool = true
    @State private var lastDragCell: (Int, Int) = (0, 0)
    @State private var dragLocation: CGPoint? = nil

    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var hintAreaHeight: CGFloat {
        let maxCount = puzzle.colHints.map { $0.count }.max() ?? 1
        let lineH: CGFloat = isIPad ? 20 : 14
        return CGFloat(maxCount) * lineH + 2
    }

    private var hintAreaWidth: CGFloat {
        let maxWidth = puzzle.rowHints.map { hints -> CGFloat in
            let totalDigits = hints.reduce(0) { $0 + String($1).count }
            let gaps = max(0, hints.count - 1)
            return CGFloat(totalDigits) * 7 + CGFloat(gaps) * 4
        }.max() ?? 16
        return max(20, min(maxWidth + 6, 80))
    }

    // ← 핵심 수정: 높이 기준 제거, 너비 기준으로만 계산 → 그리드가 항상 가로로 꽉 참
    private func cellSize(in size: CGSize) -> CGFloat {
        let spacing = CGFloat(puzzle.size - 1)
        let availableW = size.width - hintAreaWidth - 4 - spacing
        return max(1, availableW / CGFloat(puzzle.size))
    }

    var body: some View {
        GeometryReader { geo in
            let cell = cellSize(in: geo.size)
            HStack(alignment: .top, spacing: 0) {
                rowHintsView(cell: cell)
                VStack(spacing: 0) {
                    colHintsView(cell: cell)
                    gridView(cell: cell)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // MARK: - 그리드
    private func gridView(cell: CGFloat) -> some View {
        let pitch = cell + 1
        return VStack(spacing: 1) {
            ForEach(0..<puzzle.size, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<puzzle.size, id: \.self) { col in
                        CellView(
                            state: puzzle.cells[row][col],
                            size: cell,
                            isRowComplete: puzzle.isRowComplete(row),
                            isColComplete: puzzle.isColComplete(col),
                            isPending: pendingCells.contains("\(row)_\(col)"),
                            isCursor: cursorVisible && row == cursorRow && col == cursorCol,
                            showXMark: showXMark,
                            cascadeStep: cascadeStep,
                            row: row, col: col,
                            pixelColor: puzzle.colorGrid?[row][col]
                        )
                    }
                }
            }
        }
        .background(Color(hex: "#7F77DD").opacity(0.35))
        .cornerRadius(8)
        .overlay(alignment: .topLeading) {
            if showDragCount, let loc = dragLocation, pendingCells.count > 1 {
                let count = pendingCells.count
                Text("\(count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isMarkingMode ? Color(hex: "#C0445A") : Color(hex: "#534AB7"))
                            .shadow(color: (isMarkingMode ? Color(hex: "#C0445A") : Color(hex: "#534AB7")).opacity(0.6), radius: 6, x: 0, y: 2)
                    )
                    .position(x: loc.x, y: max(loc.y - cell * 3.0, 20))
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: count)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    let col = Int(value.location.x / pitch)
                    let row = Int(value.location.y / pitch)
                    guard row >= 0, row < puzzle.size, col >= 0, col < puzzle.size else { return }
                    lastDragCell = (row, col)
                    dragLocation = value.location
                    if dragStartCell == nil {
                        onDragStarted?()
                        dragStartCell = (row, col)
                        if isMarkingMode { markDragging = puzzle.cells[row][col] != .marked }
                        else { dragFilling = puzzle.cells[row][col] == .empty }
                        pendingCells.insert("\(row)_\(col)")
                        return
                    }
                    guard let start = dragStartCell else { return }
                    guard dragFillEnabled else { return }
                    if lockedAxis == nil {
                        let dx = abs(value.translation.width), dy = abs(value.translation.height)
                        if dx > 4 || dy > 4 { lockedAxis = dx > dy ? .horizontal : .vertical }
                    }
                    switch lockedAxis {
                    case .horizontal:
                        let fixedRow = start.0; let clampedCol = max(0, min(puzzle.size-1, col))
                        pendingCells = Set((min(start.1,clampedCol)...max(start.1,clampedCol)).map { "\(fixedRow)_\($0)" })
                    case .vertical:
                        let fixedCol = start.1; let clampedRow = max(0, min(puzzle.size-1, row))
                        pendingCells = Set((min(start.0,clampedRow)...max(start.0,clampedRow)).map { "\($0)_\(fixedCol)" })
                    case nil:
                        pendingCells = ["\(start.0)_\(start.1)"]
                    }
                }
                .onEnded { _ in
                    guard let start = dragStartCell else {
                        dragStartCell=nil; lockedAxis=nil; pendingCells=[]
                        dragLocation=nil; return
                    }
                    let ordered: [(Int,Int)]
                    if !dragFillEnabled {
                        ordered = [(start.0, start.1)]
                    } else {
                        switch lockedAxis {
                        case .horizontal:
                            let fixedRow=start.0
                            let cols=pendingCells.compactMap{k->Int? in let p=k.split(separator:"_"); guard Int(p[0])==fixedRow else{return nil}; return Int(p[1])}.sorted{start.1 <= $0 ? $0<$1 : $0>$1}
                            ordered=cols.map{(fixedRow,$0)}
                        case .vertical:
                            let fixedCol=start.1
                            let rows=pendingCells.compactMap{k->Int? in let p=k.split(separator:"_"); guard Int(p[1])==fixedCol else{return nil}; return Int(p[0])}.sorted{start.0 <= $0 ? $0<$1 : $0>$1}
                            ordered=rows.map{($0,fixedCol)}
                        case nil:
                            ordered=pendingCells.compactMap{k in let p=k.split(separator:"_"); guard let r=Int(p[0]),let c=Int(p[1]) else{return nil}; return(r,c)}
                        }
                    }
                    if isMarkingMode {
                        for (r,c) in ordered { onMarkToggle?(r,c,markDragging) }
                    } else {
                        for (r,c) in ordered {
                            // 시작 칸이 이미 채워져 있어도 첫 오답에서 멈춘다 (목숨 연속 차감 방지)
                            let isWrong = puzzle.cells[r][c] == .empty && !puzzle.solution[r][c]
                            onTap(r,c)
                            if isWrong { break }
                        }
                    }
                    onLastCell?(lastDragCell.0, lastDragCell.1)
                    dragStartCell=nil; lockedAxis=nil; pendingCells=[]
                    withAnimation(.easeOut(duration: 0.15)) { dragLocation = nil }
                }
        )
    }

    // MARK: - 행 힌트
    private func rowHintsView(cell: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Color.clear.frame(height: hintAreaHeight)
            VStack(alignment: .trailing, spacing: 1) {
                ForEach(0..<puzzle.size, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(Array(puzzle.rowHints[row].enumerated()), id: \.offset) { idx, hint in
                            hintText(hint, isRow: true, lineIdx: row, hintIdx: idx)
                        }
                    }.frame(height: cell)
                }
            }
            .frame(width: hintAreaWidth)
            .background(Color(hex: "#0d0b1a").opacity(0.92))
        }
        .frame(width: hintAreaWidth)
        .padding(.trailing, 2)
    }

    // MARK: - 열 힌트
    private func colHintsView(cell: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(0..<puzzle.size, id: \.self) { col in
                VStack(spacing: 1) {
                    Spacer(minLength: 0)
                    ForEach(Array(puzzle.colHints[col].enumerated()), id: \.offset) { idx, hint in
                        hintText(hint, isRow: false, lineIdx: col, hintIdx: idx)
                            .frame(width: cell).lineLimit(1)
                            .minimumScaleFactor(isIPad ? 0.8 : 0.6)
                    }
                }
                .frame(width: cell, height: hintAreaHeight)
            }
        }
        .background(Color(hex: "#0d0b1a").opacity(0.92))
    }

    // MARK: - 힌트 숫자 공통 뷰
    @ViewBuilder
    private func hintText(_ hint: Int, isRow: Bool, lineIdx: Int, hintIdx: Int) -> some View {
        let lineComplete = isRow ? puzzle.isRowComplete(lineIdx) : puzzle.isColComplete(lineIdx)
        let satisfied = !lineComplete && (isRow
            ? puzzle.isRowHintSatisfied(lineIdx, at: hintIdx)
            : puzzle.isColHintSatisfied(lineIdx, at: hintIdx))

        Text("\(hint)")
            .font(.system(size: isIPad ? 16 : 12, weight: .semibold, design: .monospaced))
            .foregroundColor(
                lineComplete ? Color(hex: "#6B6499")
                : satisfied  ? Color(hex: "#5EC48A")
                :              Color(hex: "#AFA9EC")
            )
    }
}

// MARK: - 셀 뷰
struct CellView: View {
    let state: CellState
    let size: CGFloat
    let isRowComplete: Bool
    let isColComplete: Bool
    var isPending: Bool = false
    var isCursor: Bool = false
    var showXMark: Bool = true
    var cascadeStep: Int = -1
    var row: Int = 0
    var col: Int = 0
    var pixelColor: Color? = nil

    private var isRevealed: Bool { cascadeStep >= row + col }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: max(1, size), height: max(1, size))
                .overlay(isPending && state == .empty
                    ? Rectangle().fill(Color(hex: "#7F77DD").opacity(0.4)) : nil)
                .overlay(isCursor
                    ? Rectangle().stroke(Color.white.opacity(0.85), lineWidth: 2) : nil)
                .scaleEffect(cascadeScale)
                .animation(cascadeStep == row + col
                    ? .spring(response: 0.25, dampingFraction: 0.5) : .none, value: cascadeStep)

            if state == .marked && showXMark {
                Text("✕")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: max(1, size) * 0.5))
                    .foregroundColor(Color(hex: "#E05C7A"))
            }
        }
    }

    private var cascadeScale: CGFloat {
        guard state == .filled else { return 1.0 }
        return cascadeStep == row + col ? 1.25 : 1.0
    }

    private var backgroundColor: Color {
        let isComplete = isRowComplete || isColComplete
        switch state {
        case .filled:
            if cascadeStep >= 0 && !isRevealed { return Color(hex: "#26215C") }
            if cascadeStep >= 0, let color = pixelColor, color != .clear { return color }
            return Color(hex: "#534AB7")
        case .marked:
            return showXMark ? Color(hex: "#1a1530") : Color(hex: "#1e1c3a")
        case .empty:
            if isCursor { return Color(hex: "#AFA9EC").opacity(0.26) }
            if isComplete { return Color(hex: "#1A4040").opacity(0.8) }
            return Color(hex: "#13112a")
        }
    }
}

#Preview {
    let solution: [[Bool]] = (0..<15).map { row in (0..<15).map { col in (row + col) % 2 == 0 } }
    return NonogramGridView(puzzle: NonogramPuzzle(size: 15, solution: solution)) { _, _ in }
        .frame(width: 390, height: 600)
}

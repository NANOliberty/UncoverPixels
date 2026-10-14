//
//  ImagePixelizer.swift
//  UncoverYourPixels
//

import UIKit
import CoreImage

struct PixelData {
    let blackWhite: [[Bool]]
    let colorGrid: [[UIColor]]
    let size: Int
    let finalDensity: Double
    let dominantColor: UIColor
}

struct ImagePixelizer {

    // MARK: - 메인 변환 함수
    static func pixelize(_ image: UIImage, targetSize: Int = 120) -> PixelData? {
        let normalized = image.fixedOrientation()
        let preprocessed = applyEdgeEnhancement(normalized) ?? normalized

        guard let resized = resize(preprocessed, to: targetSize),
              let cgImage = resized.cgImage else { return nil }

        let width  = cgImage.width
        let height = cgImage.height
        guard let pixelBuffer = getPixelData(from: cgImage) else { return nil }

        let targetRange: ClosedRange<Double> = 0.30...0.60
        let maxAttempts = 6
        var threshold: Double = 0.5
        var colorGrid:  [[UIColor]] = []
        var blackWhite: [[Bool]]    = []
        var density:    Double      = 0

        for attempt in 0..<maxAttempts {
            (colorGrid, blackWhite) = buildGrids(
                pixelBuffer: pixelBuffer,
                width: width, height: height,
                threshold: threshold
            )
            let filled = blackWhite.flatMap { $0 }.filter { $0 }.count
            density = Double(filled) / Double(width * height)
            if targetRange.contains(density) { break }
            if attempt == maxAttempts - 1 { break }
            if density < targetRange.lowerBound { threshold -= 0.07 } else { threshold += 0.07 }
            threshold = max(0.1, min(0.9, threshold))
        }

        let dominant = extractDominantColor(from: pixelBuffer, width: width, height: height)

        return PixelData(
            blackWhite: blackWhite,
            colorGrid: colorGrid,
            size: targetSize,
            finalDensity: density,
            dominantColor: dominant
        )
    }

    // MARK: - Dominant Color 추출
    static func extractDominantColor(from pixelBuffer: [UInt8], width: Int, height: Int) -> UIColor {
        let bucketSize = 16
        var buckets = [Int: (r: Double, g: Double, b: Double, count: Int)]()
        let step = max(1, (width * height) / 1000)
        for i in stride(from: 0, to: width * height, by: step) {
            let offset = i * 4
            let r = Int(pixelBuffer[offset]); let g = Int(pixelBuffer[offset+1]); let b = Int(pixelBuffer[offset+2])
            let maxC = max(r, g, b); let minC = min(r, g, b)
            let saturation = maxC > 0 ? Double(maxC - minC) / Double(maxC) : 0
            guard saturation > 0.2 && maxC > 30 && minC < 220 else { continue }
            let key = (r / bucketSize) * 10000 + (g / bucketSize) * 100 + (b / bucketSize)
            if let existing = buckets[key] {
                buckets[key] = (r: existing.r + Double(r), g: existing.g + Double(g),
                                b: existing.b + Double(b), count: existing.count + 1)
            } else {
                buckets[key] = (r: Double(r), g: Double(g), b: Double(b), count: 1)
            }
        }
        guard let dominant = buckets.values.max(by: { $0.count < $1.count }) else {
            return UIColor(red: 0.2, green: 0.15, blue: 0.4, alpha: 1)
        }
        let count = Double(dominant.count)
        return UIColor(red: CGFloat(dominant.r / count / 255),
                       green: CGFloat(dominant.g / count / 255),
                       blue: CGFloat(dominant.b / count / 255), alpha: 1)
    }

    // MARK: - 엣지 강조
    private static func applyEdgeEnhancement(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()
        let sharpened = ciImage
            .applyingFilter("CIUnsharpMask", parameters: ["inputRadius": 2.5, "inputIntensity": 1.2])
            .applyingFilter("CIColorControls", parameters: [
                "inputContrast": 1.3,
                "inputSaturation": 0.8,
                "inputBrightness": 0.0
            ])
        guard let cgResult = context.createCGImage(sharpened, from: sharpened.extent) else { return nil }
        return UIImage(cgImage: cgResult)
    }

    // MARK: - 그리드 빌드
    private static func buildGrids(
        pixelBuffer: [UInt8], width: Int, height: Int, threshold: Double
    ) -> (colorGrid: [[UIColor]], blackWhite: [[Bool]]) {
        var colorGrid:  [[UIColor]] = []
        var blackWhite: [[Bool]]    = []
        for row in 0..<height {
            var colorRow: [UIColor] = []
            var bwRow:    [Bool]    = []
            for col in 0..<width {
                let offset = (row * width + col) * 4
                let r = CGFloat(pixelBuffer[offset])     / 255.0
                let g = CGFloat(pixelBuffer[offset + 1]) / 255.0
                let b = CGFloat(pixelBuffer[offset + 2]) / 255.0
                let a = CGFloat(pixelBuffer[offset + 3]) / 255.0
                colorRow.append(UIColor(red: r, green: g, blue: b, alpha: a))
                let brightness = 0.299 * r + 0.587 * g + 0.114 * b
                bwRow.append(Double(brightness) < threshold)
            }
            colorGrid.append(colorRow)
            blackWhite.append(bwRow)
        }
        return (colorGrid, blackWhite)
    }

    // MARK: - 타일 분할
    static func splitIntoTiles(pixelData: PixelData, difficulty: Difficulty) -> [[NonogramPuzzle]] {
        let tileSize  = difficulty.gridSize
        let tileCount = pixelData.size / tileSize
        var tiles: [[NonogramPuzzle]] = []

        for tileRow in 0..<tileCount {
            var row: [NonogramPuzzle] = []
            for tileCol in 0..<tileCount {
                var solution = extractTile(from: pixelData.blackWhite,
                                           tileRow: tileRow, tileCol: tileCol, tileSize: tileSize)

                let totalCells  = tileSize * tileSize
                let filledCount = solution.flatMap { $0 }.filter { $0 }.count
                let density     = Double(filledCount) / Double(totalCells)

                let emptyRowCount = solution.filter { !$0.contains(true) }.count
                let emptyColCount = (0..<tileSize).filter { col in
                    !(0..<tileSize).contains { row in solution[row][col] }
                }.count

                // 빈 행/열 2개 초과 시 교체 (기존: tileSize / 2 → 너무 관대했음)
                let tooSparse = emptyRowCount > 2 || emptyColCount > 2

                var puzzle: NonogramPuzzle
                if density == 0 || density > 0.82 || density < 0.18 || tooSparse {
                    solution = generateRandomSolution(size: tileSize,
                                                      targetDensity: Double.random(in: 0.35...0.55))
                    puzzle = NonogramPuzzle(size: tileSize, solution: solution)
                } else {
                    puzzle = NonogramPuzzle(size: tileSize, solution: solution)
                }
                row.append(puzzle)
            }
            tiles.append(row)
        }
        return tiles
    }

    // MARK: - 랜덤 노노그램 (blob 성장 + 빈 행/열 보정)
    private static func generateRandomSolution(size: Int, targetDensity: Double) -> [[Bool]] {
        var solution = Array(repeating: Array(repeating: false, count: size), count: size)
        // 최소 각 행/열 1개 보장을 위해 targetCount 하한선 높임
        let targetCount = max(size * 2, Int(Double(size * size) * targetDensity))
        var filled = 0
        let dirs = [(-1,0),(1,0),(0,-1),(0,1)]
        let seedCount = Int.random(in: 4...8)
        var frontier: [(Int, Int)] = []
        for _ in 0..<seedCount {
            let sr = Int.random(in: 0..<size); let sc = Int.random(in: 0..<size)
            if !solution[sr][sc] { solution[sr][sc] = true; filled += 1; frontier.append((sr, sc)) }
        }
        while filled < targetCount && !frontier.isEmpty {
            let idx = Int.random(in: 0..<frontier.count)
            let (r, c) = frontier[idx]; frontier.remove(at: idx)
            for (dr, dc) in dirs.shuffled() {
                guard filled < targetCount else { break }
                let nr = r + dr; let nc = c + dc
                guard nr >= 0, nr < size, nc >= 0, nc < size, !solution[nr][nc] else { continue }
                if Double.random(in: 0...1) < 0.50 {
                    solution[nr][nc] = true; filled += 1; frontier.append((nr, nc))
                }
            }
        }

        // 빈 행 보정: 각 행에 최소 1개 셀 보장
        for row in 0..<size {
            if !solution[row].contains(true) {
                solution[row][Int.random(in: 0..<size)] = true
            }
        }
        // 빈 열 보정: 각 열에 최소 1개 셀 보장
        for col in 0..<size {
            if !(0..<size).contains(where: { solution[$0][col] }) {
                solution[Int.random(in: 0..<size)][col] = true
            }
        }

        return solution
    }

    private static func extractTile(from grid: [[Bool]], tileRow: Int, tileCol: Int, tileSize: Int) -> [[Bool]] {
        let startRow = tileRow * tileSize; let startCol = tileCol * tileSize
        return (startRow..<startRow + tileSize).map { row in
            (startCol..<startCol + tileSize).map { col in grid[row][col] }
        }
    }

    private static func resize(_ image: UIImage, to size: Int) -> UIImage? {
        let targetSize = CGSize(width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }

    private static func getPixelData(from cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width; let height = cgImage.height
        let bytesPerRow = width * 4
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &pixelData, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelData
    }
}

// MARK: - UIImage EXIF 회전 정규화
extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalized
    }
}

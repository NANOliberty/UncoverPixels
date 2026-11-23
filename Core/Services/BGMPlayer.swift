//
//  BGMPlayer.swift
//  UncoverYourPixels
//
//  배경음악 재생. 캐주얼 게임의 일반적인 방식을 따른다.
//  - .ambient 카테고리라 무음 스위치를 존중하고 다른 앱 음악을 끊지 않는다
//  - 사용자가 다른 앱으로 음악을 듣고 있으면 배경음악을 틀지 않는다
//  - 퍼즐을 푸는 동안과 광고 중에는 소리를 줄였다가 돌아온다
//

import AVFoundation
import UIKit

@MainActor
final class BGMPlayer {
    static let shared = BGMPlayer()

    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?

    /// 설정에서 끄면 아예 재생하지 않는다
    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "bgmEnabled") as? Bool ?? true
    }
    /// 잠시 물러나야 하는 이유. 하나라도 남아 있으면 소리를 내지 않는다
    enum SuspendReason: Hashable {
        case puzzle   // 퍼즐을 푸는 동안
        case ad       // 광고가 떠 있는 동안
    }
    private var suspendReasons: Set<SuspendReason> = []
    private var isSuspended: Bool { !suspendReasons.isEmpty }

    private let fullVolume: Float = 0.5
    private let fadeDuration: TimeInterval = 0.6

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
    }

    // MARK: - 외부에서 부르는 것들

    /// 앱이 화면에 올라왔을 때
    func activate() {
        guard isEnabled, !isSuspended else { return }
        guard !AVAudioSession.sharedInstance().isOtherAudioPlaying else {
            // 사용자가 듣던 음악을 가리지 않는다
            stop()
            return
        }
        prepareIfNeeded()
        guard let player, !player.isPlaying else { return }
        player.volume = 0
        player.play()
        fade(to: fullVolume)
    }

    /// 앱이 백그라운드로 갈 때
    func deactivate() {
        fadeTimer?.invalidate()
        player?.pause()
        deactivateSession()
    }

    /// 퍼즐 화면에 들어갈 때, 광고가 뜰 때처럼 잠시 비켜야 할 때
    func suspend(_ reason: SuspendReason) {
        suspendReasons.insert(reason)
        fade(to: 0) { [weak self] in self?.player?.pause() }
    }

    /// 비켰던 이유가 사라졌을 때. 다른 이유가 남아 있으면 계속 멈춰 있는다
    func resume(_ reason: SuspendReason) {
        suspendReasons.remove(reason)
        activate()
    }

    /// 설정 토글이 바뀌었을 때
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "bgmEnabled")
        if enabled {
            activate()
        } else {
            fade(to: 0) { [weak self] in self?.stop() }
        }
    }

    // MARK: - 내부

    private func prepareIfNeeded() {
        guard player == nil else { return }
        guard let url = Bundle.main.url(forResource: "UYP_BGM", withExtension: "caf") else {
            print("⚠️ 배경음악 파일을 찾지 못했습니다")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1      // 무한 반복
            p.volume = 0
            p.prepareToPlay()
            player = p
        } catch {
            print("⚠️ 배경음악을 준비하지 못했습니다: \(error.localizedDescription)")
        }
    }

    private func stop() {
        fadeTimer?.invalidate()
        player?.stop()
        player?.currentTime = 0
        deactivateSession()
    }

    private func deactivateSession() {
        // 다른 앱이 다시 소리를 낼 수 있도록 세션을 놓아준다
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func fade(to target: Float, completion: (() -> Void)? = nil) {
        fadeTimer?.invalidate()
        guard let player else { completion?(); return }

        let step = 0.05
        let diff = target - player.volume
        guard abs(diff) > 0.001 else { player.volume = target; completion?(); return }
        let delta = Float(step / fadeDuration) * diff

        fadeTimer = Timer.scheduledTimer(withTimeInterval: step, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self, let player = self.player else { timer.invalidate(); return }
                player.volume += delta
                let reached = delta > 0 ? player.volume >= target : player.volume <= target
                if reached {
                    player.volume = target
                    timer.invalidate()
                    completion?()
                }
            }
        }
    }

    @objc private nonisolated func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }

        Task { @MainActor in
            switch type {
            case .began:
                // 전화, 광고 영상 등으로 소리가 끊길 때
                self.player?.pause()
            case .ended:
                let options = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
                if options.contains(.shouldResume) { self.activate() }
            @unknown default:
                break
            }
        }
    }
}

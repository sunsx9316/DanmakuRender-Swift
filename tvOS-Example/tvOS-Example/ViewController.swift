//
//  ViewController.swift
//  tvOS-Example
//

import UIKit
import DanmakuRender

class ViewController: UIViewController {

    private lazy var danmakuEngine: DanmakuEngine = {
        let engine = DanmakuEngine()
        engine.speed = 0.8
        return engine
    }()

    private var sendTimer: Timer?

    private var increaseCount = 0

    private var isPaused = false

    private var currentSpeed: CGFloat = 0.8 {
        didSet {
            danmakuEngine.speed = currentSpeed
        }
    }

    private var currentFontSize: CGFloat = 30 {
        didSet {
            let font = UIFont.systemFont(ofSize: currentFontSize)
            for con in danmakuEngine.containers {
                con.danmaku.font = font
            }
        }
    }

    private var currentEffectStyle: DanmakuEffectStyle = .stroke

    private let danmakuTexts = [
        "你好世界",
        "Apple TV 弹幕测试",
        "Swift 弹幕引擎",
        "DanmakuRender",
        "666666",
        "前方高能",
        " tvOS 适配成功"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        view.addSubview(danmakuEngine.canvas)

        danmakuEngine.start()

        // 自动发送弹幕
        sendTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let text = self.danmakuTexts.randomElement() ?? "弹幕"
            let danmaku = ScrollDanmaku(
                text: "\(text) \(self.increaseCount)",
                textColor: .white,
                font: .systemFont(ofSize: self.currentFontSize),
                effectStyle: self.currentEffectStyle,
                direction: .toRight
            )
            self.danmakuEngine.send(danmaku)
            self.increaseCount += 1
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        danmakuEngine.canvas.frame = view.bounds
    }

    // MARK: - Focus Actions

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesBegan(presses, with: event)
            return
        }

        switch press.type {
        case .playPause:
            if isPaused {
                isPaused = false
                danmakuEngine.start()
            } else {
                isPaused = true
                danmakuEngine.pause()
            }
        case .select:
            // 手动发送一个浮动弹幕
            let floatDanmaku = FloatDanmaku(
                text: " 浮动 \(increaseCount)",
                textColor: .yellow,
                font: .systemFont(ofSize: currentFontSize),
                effectStyle: .glow,
                position: .atTop,
                lifeTime: 3
            )
            danmakuEngine.send(floatDanmaku)
            increaseCount += 1
        case .leftArrow:
            currentSpeed = max(0.2, currentSpeed - 0.1)
        case .rightArrow:
            currentSpeed = min(3.0, currentSpeed + 0.1)
        case .upArrow:
            currentFontSize = min(60, currentFontSize + 2)
        case .downArrow:
            currentFontSize = max(14, currentFontSize - 2)
        default:
            super.pressesBegan(presses, with: event)
            return
        }
    }
}

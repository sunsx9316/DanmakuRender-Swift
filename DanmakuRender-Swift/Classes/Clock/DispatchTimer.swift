//
//  DispatchTimer.swift
//  DanmakuRender-Swift
//
//  基于 DispatchSourceTimer 的定时器，后台可用。
//  用于替代 CADisplayLink，在 PiP 等后台场景中保持弹幕引擎运行。
//

import Foundation

class DispatchTimer: DisplayLinkProtocol {

    private var dispatchTimer: DispatchSourceTimer?
    private weak var target: AnyObject?
    private let selector: Selector
    private var isRunning = false

    init(_ target: AnyObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }

    func resume() {
        guard !isRunning else { return }
        isRunning = true

        let timer = DispatchSource.makeTimerSource(queue: .main)
        let interval = 1.0 / 60.0
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            _ = self?.target?.perform(self?.selector)
        }
        self.dispatchTimer = timer
        timer.resume()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false

        dispatchTimer?.cancel()
        dispatchTimer = nil
    }

    deinit {
        if let timer = dispatchTimer {
            timer.setEventHandler(handler: nil)
            timer.cancel()
        }
    }
}

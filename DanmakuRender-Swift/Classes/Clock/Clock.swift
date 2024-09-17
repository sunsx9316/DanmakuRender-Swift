//
//  Clock.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/2.
//

import Foundation
#if os(iOS)
import UIKit
#endif

protocol ClockDelegate: AnyObject {
    func clock(_ clock: Clock, didChange time: TimeInterval)
}

/// 时钟
class Clock {
    
    weak var delegate: ClockDelegate?
    
    /// 偏移时间
    var offset: TimeInterval = 0
    
    /// 速度
    var speed: Double = 1
    
    /// 当前时间
    var time: TimeInterval = 0 {
        didSet {
            self.delegate?.clock(self, didChange: self.time + self.offset)
        }
    }
    
    /// 上一次记录的时间
    private var previousTime: CFTimeInterval = 0
    
    private var displayLink: DisplayLink?
    
    private var isRunning = false
    
    func start() {
        if self.isRunning {
            return
        }
        
        self.previousTime = CACurrentMediaTime()
        self.isRunning = true
        if self.displayLink == nil {
            self.displayLink = DisplayLink(self, selector: #selector(Clock.displayLinkCallBack))
        }
        self.displayLink?.resume()
    }
    
    func stop() {
        self.previousTime = 0
        self.time = 0
        self.isRunning = false
        self.displayLink = nil
    }
    
    func pause() {
        if !self.isRunning {
            return
        }
        
        self.isRunning = false
        self.displayLink?.pause()
    }
    
    @objc private func displayLinkCallBack() {
        let currentTime = CACurrentMediaTime()
        if self.isRunning {
            self.time += (currentTime - self.previousTime) * self.speed;
        }
        self.previousTime = CACurrentMediaTime()
        self.delegate?.clock(self, didChange: self.time + self.offset)
    }
    
}

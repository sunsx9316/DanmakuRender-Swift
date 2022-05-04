//
//  ScrollDanmaku.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation

open class ScrollDanmaku: BaseDanmaku {
    
    /// 滚动方向
    public enum Direction {
        /// 向右滚动
        case toRight
        /// 向左滚动
        case toLeft
    }
    
    public let direction: Direction
    
    /// 额外附加速度
    public var extraSpeed: CGFloat = 1
    
    /// 弹幕完全消失的时间
    private var didDisappearTime: TimeInterval = 0
    
    /// 弹幕即将消失的时间
    private var willDisappearTime: TimeInterval = 0
    
    /// 弹幕速度
    private var speed: Double = 0
    
    /// 基础速度
    private let basicSpeed: Double = 100
    
    /// 弹幕长度系数 用于调整速度
    private let lengthCoefficient: Double = 1300
    
    /// 弹幕最小间距
    private let danmakuGap: Double = 8
    
    /// 初始位置
    private var originPosition = CGPoint.zero
    
    /// 初始化
    /// - Parameters:
    ///   - text: 文字
    ///   - textColor: 文字颜色
    ///   - font: 字体
    ///   - effectStyle: 边缘风格
    ///   - direction: 滚动方向
    public init(text: String,
                textColor: DRColor,
                font: DRFont,
                effectStyle: DanmakuEffectStyle,
                direction: Direction) {
        self.direction = direction
        super.init(text: text, textColor: textColor, font: font, effectStyle: effectStyle)
    }
    
    //MARK: - DanmakuProtocol
    public override func willAddToCanvas(_ context: DanmakuContext) {
        super.willAddToCanvas(context)
        
        //基础速度 加上 根据弹幕宽度控制的速度加成
        self.speed = ceil(self.basicSpeed + ((context.container.frame.width / self.lengthCoefficient) * self.basicSpeed))
        self.willDisappearTime = self.calculateWillDisappearTime(context, speed: self.speed, appearTime: self.appearTime)
        self.didDisappearTime = self.calculateDidDisappearTime(context, willDisappearTime: self.willDisappearTime)
        
        //根据弹幕尺寸确定所在轨道
        let trackHeight = self.trackHeight(context)
        let trackCount = max(Int(context.canvas.bounds.height / trackHeight), self.minTrackCount)
        
        //找到某个轨道下最后消失的弹幕
        var trackInfo = [Int: Self]()
        for container in context.activeContainers {
            if let newValue = container.danmaku as? Self,
               newValue !== self {
                let tmpTrack = newValue.track
                
                if let oldValue = trackInfo[tmpTrack] {
                    if newValue.didDisappearTime > oldValue.didDisappearTime {
                        trackInfo[tmpTrack] = newValue
                    }
                } else {
                    trackInfo[tmpTrack] = newValue
                }
            }
        }
        
        var sendInTrack: Int?
        
        let selfWillAppearTime = self.appearTime - (context.engineTime - self.appearTime)
        for i in 0..<trackCount {
            if let danmaku = trackInfo[i] {
                let danmakuDidAppearTime = danmaku.appearTime + (danmaku.didDisappearTime - danmaku.willDisappearTime)
                //加一个最小间距
                let gapTime = self.danmakuGap / self.realSpeed(speed: danmaku.speed)
                //弹幕即将消失的时间比轨道中最后一个弹幕完全消失的时间大 且
                //弹幕即将出现在屏幕上的时间比轨道中最后一个弹幕完全出现的时间大 则不可能发生碰撞
                if self.willDisappearTime > danmaku.didDisappearTime && selfWillAppearTime > danmakuDidAppearTime + gapTime {
                    sendInTrack = i
                    break
                }
            } else {
                //当前轨道没有弹幕
                sendInTrack = i
                break
            }
        }
        
        //还是没找到轨道，则随机分配一条
        if sendInTrack == nil {
            sendInTrack = Int.random(in: 0..<trackCount)
        }
        
        self.track = sendInTrack!
        
        var danmakuFrame = context.container.frame
        //在轨道居中显示
        danmakuFrame.origin.x = self.startX(context, speed: self.speed, appearTime: self.appearTime)
        danmakuFrame.origin.y = (trackHeight * CGFloat(self.track)) + ((trackHeight - danmakuFrame.height) / 2)
        self.originPosition = danmakuFrame.origin
        context.container.frame = danmakuFrame
    }
    
    public override func shouldMoveOutCanvas(_ context: DanmakuContext) -> Bool {
        switch self.direction {
        case .toRight:
            return context.container.frame.minX >= context.canvas.bounds.maxX
        case .toLeft:
            return context.container.frame.maxX <= context.canvas.bounds.minX
        }
    }
    
    public override func update(context: DanmakuContext) {
        var frame = context.container.frame
        let timeDiffOffset = self.timeDiffOffset(context, speed: self.speed, appearTime: self.appearTime)
        
        switch self.direction {
        case .toLeft:
            frame.origin.x = self.originPosition.x - timeDiffOffset
        case .toRight:
            frame.origin.x = self.originPosition.x + timeDiffOffset
        }
        
        context.container.frame = frame
    }
    
    public override func didLayout(_ context: DanmakuContext) {
        self.willDisappearTime = self.calculateWillDisappearTime(context, speed: self.speed, appearTime: self.appearTime)
        self.didDisappearTime = self.calculateDidDisappearTime(context, willDisappearTime: self.willDisappearTime)
        let trackHeight = self.trackHeight(context)
        let danmakuFrame = context.container.frame
        //在轨道居中显示
        self.originPosition.y = (trackHeight * CGFloat(self.track)) + ((trackHeight - danmakuFrame.height) / 2)
        context.container.frame.origin.y = self.originPosition.y
    }
    
    //MARK: - Private Method
    
    /// 计算弹幕即将消失的时间
    private func calculateWillDisappearTime(_ context: DanmakuContext, speed: Double, appearTime: TimeInterval) -> Double {
        let realSpeed = self.realSpeed(speed: speed)
        let startX = self.startX(context, speed: speed, appearTime: appearTime)
        switch self.direction {
        case .toLeft:
            return appearTime + (startX / realSpeed)
        case .toRight:
            return appearTime + ((context.canvas.bounds.width - startX) / realSpeed)
        }
    }
    
    /// 计算弹幕完全消失的时间
    private func calculateDidDisappearTime(_ context: DanmakuContext, willDisappearTime: TimeInterval) -> Double {
        let realSpeed = self.realSpeed(speed: speed)
        return willDisappearTime + context.container.frame.width / realSpeed
    }
    
    
    /// 弹幕实际的速度
    private func realSpeed(speed: CGFloat) -> Double {
        let moveSpeed = speed * self.extraSpeed
        return moveSpeed
    }
    
    /// 计算弹幕初始位置X
    private func startX(_ context: DanmakuContext, speed: CGFloat, appearTime: TimeInterval) -> CGFloat {
        let timeDiffOffset = abs(self.timeDiffOffset(context, speed: speed, appearTime: appearTime))
        let x: CGFloat
        switch self.direction {
        case .toRight:
            x = context.canvas.bounds.minX - context.container.frame.width - timeDiffOffset
        case .toLeft:
            x = context.canvas.bounds.maxX + timeDiffOffset
        }
        return x
    }
    
    /// 计算弹幕距离即将显示在屏幕上的时间差
    private func timeDiffOffset(_ context: DanmakuContext, speed: CGFloat, appearTime: TimeInterval) -> CGFloat {
        let realSpeed = self.realSpeed(speed: speed)
        let diff = (context.engineTime - appearTime) * realSpeed
        return diff
    }
}

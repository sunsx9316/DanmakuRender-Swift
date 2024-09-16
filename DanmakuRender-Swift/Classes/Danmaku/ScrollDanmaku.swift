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
    private let danmakuGap: Double = 10
    
    /// 初始位置
    private var originPosition = CGPoint.zero
    
    /// 真正的速度
    private var realSpeed: CGFloat {
        return self.speed * self.extraSpeed
    }
    
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
    open override func shouldAddToCanvas(_ context: DanmakuContext) -> Bool {
        let flag = super.shouldAddToCanvas(context)
        
        let containerSize = context.container.frame.size
        let canvasBounds = context.canvas.bounds
        self.speed = ceil(self.basicSpeed + ((containerSize.width / self.lengthCoefficient) * self.basicSpeed))
        let realSpeed = self.realSpeed
        let timeDiffOffset = (self.appearTime - context.engineTime) * realSpeed
        let start: CGFloat
        switch self.direction {
        case .toLeft:
            start = canvasBounds.width + timeDiffOffset
            self.willDisappearTime = self.appearTime + (canvasBounds.width / realSpeed)
        case .toRight:
            start = -containerSize.width - timeDiffOffset
            self.willDisappearTime = self.appearTime + (canvasBounds.width / realSpeed)
        }
        self.didDisappearTime = containerSize.width / realSpeed + self.willDisappearTime
        
        //根据弹幕尺寸确定所在轨道
        let trackHeight = self.trackHeight(context)
        let trackCount = max(Int(canvasBounds.height / trackHeight), self.minTrackCount)
        
        //找到某个轨道下最后消失的弹幕
        var trackInfo = [Int: (danmaku:ScrollDanmaku, container: DanmakuContainerProtocol)]()
        for container in context.activeContainers {
            if let newValue = container.danmaku as? Self,
               newValue !== self {
                let tmpTrack = newValue.track
                
                if let oldValue = trackInfo[tmpTrack] {
                    if newValue.didDisappearTime > oldValue.danmaku.didDisappearTime {
                        trackInfo[tmpTrack] = (newValue, container)
                    }
                } else {
                    trackInfo[tmpTrack] = (newValue, container)
                }
            }
        }
        
        var sendInTrack: Int?
        
        for i in 0..<trackCount {
            if let (danmaku, container) = trackInfo[i] {

                let danmakuRealSpeed = danmaku.realSpeed
                
                //在这条弹幕发射时，两条弹幕的间距
                let distance: CGFloat
                
                switch danmaku.direction {
                case .toRight:
                    distance = danmaku.positionOffset(at: self.appearTime)
                case .toLeft:
                    distance = canvasBounds.width - (danmaku.positionOffset(at: self.appearTime) + container.frame.width)
                }
                
                /// 保持一个最小的间距
                if distance > self.danmakuGap {
                    if realSpeed > danmakuRealSpeed {
                        /// 弹幕相遇时间 = 弹幕间距 / 弹幕的速度差
                        /// 如果相遇的时间 > 弹幕走完整个屏幕的时间，则认为不会相遇
                        let catchUpTime = distance / (realSpeed - danmakuRealSpeed)
                        let lifeTime = canvasBounds.width / realSpeed
                        if catchUpTime >= lifeTime {
                            sendInTrack = i
                            break
                        }
                    } else {
                        sendInTrack = i
                        break
                    }
                }
                
            } else {
                //当前轨道没有弹幕
                sendInTrack = i
                break
            }
        }
        
        //还是没找到轨道，则随机分配一条
        if sendInTrack == nil {
            switch context.layoutStyle {
            case .timely:
                sendInTrack = Int.random(in: 0..<trackCount)
            case .nonOverlapping:
                //不重叠的布局风格，会忽略某些弹幕
                return false
            }
        }
        
        if let sendInTrack = sendInTrack {
            self.track = sendInTrack
        } else {
            self.track = 0
            assert(false, "未找到轨道")
        }
        
        //在轨道居中显示
        self.originPosition = .init(x: start,
                                    y: (trackHeight * CGFloat(self.track)) + ((trackHeight - containerSize.height) / 2))
        context.container.frame.origin = self.originPosition
        
        return flag
    }
    
    open override func shouldMoveOutCanvas(_ context: DanmakuContext) -> Bool {
        switch self.direction {
        case .toRight:
            return context.container.frame.minX >= context.canvas.bounds.width
        case .toLeft:
            return context.container.frame.maxX <= 0
        }
    }
    
    open override func update(context: DanmakuContext) {
        super.update(context: context)
        var frame = context.container.frame
        frame.origin.x = self.positionOffset(at: context.engineTime)
        context.container.frame = frame
    }
    
    open override func doResize(_ context: DanmakuContext) {
        super.doResize(context)
        
        let realSpeed = self.realSpeed
        
        switch self.direction {
        case .toLeft:
            self.willDisappearTime = context.engineTime + (context.container.frame.minX / realSpeed)
        case .toRight:
            self.willDisappearTime = context.engineTime + ((context.canvas.bounds.width - context.container.frame.maxX) / realSpeed)
        }
        self.didDisappearTime = context.container.frame.width / realSpeed + self.willDisappearTime
        
        
        let trackHeight = self.trackHeight(context)
        let danmakuFrame = context.container.frame
        //在轨道居中显示
        self.originPosition.y = (trackHeight * CGFloat(self.track)) + ((trackHeight - danmakuFrame.height) / 2)
        context.container.frame.origin.y = self.originPosition.y
    }
    
    //MARK: - Private Method
    
    
    /// 弹幕的偏移量
    /// - Parameter time: 所处时间
    /// - Returns: 偏移量
    private func positionOffset(at time: TimeInterval) -> CGFloat {
        
        let realSpeed = self.realSpeed
        let timeDiffOffset: CGFloat
        
        let timePast = self.offsetTime ?? 0
        
        if let pauseTime = self.pauseTime {
            /// 被暂停时，相当于弹幕当前的时间停止了
            timeDiffOffset = (pauseTime - (self.appearTime + timePast)) * realSpeed
        } else {
            timeDiffOffset = (time - (self.appearTime + timePast)) * realSpeed
        }
        
        switch self.direction {
        case .toLeft:
            return self.originPosition.x - timeDiffOffset
        case .toRight:
            return self.originPosition.x + timeDiffOffset
        }
    }
}

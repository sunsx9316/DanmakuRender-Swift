//
//  FloatDanmaku.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/2.
//

import Foundation

open class FloatDanmaku: BaseDanmaku {
    
    /// 出现的位置
    public enum Position {
        /// 出现在底部
        case atBottom
        /// 出现在顶部
        case atTop
    }
    
    private let lifeTime: TimeInterval
    
    private let position: Position
    
    public init(text: String,
                textColor: DRColor,
                font: DRFont,
                effectStyle: DanmakuEffectStyle,
                position: Position,
                lifeTime: TimeInterval) {
        self.position = position
        self.lifeTime = lifeTime
        
        super.init(text: text, textColor: textColor, font: font, effectStyle: effectStyle)
    }
    
    open override func shouldAddToCanvas(_ context: DanmakuContext) -> Bool {
        let flag = super.shouldAddToCanvas(context)

        //根据弹幕尺寸确定所在轨道
        let trackHeight = self.trackHeight(context)
        let trackCount = max(Int(context.canvas.bounds.height / trackHeight), self.minTrackCount)
        
        //统计轨道弹幕数
        var trackInfo = [Int: Int]()
        for container in context.activeContainers {
            if let newDanmaku = container.danmaku as? Self,
                newDanmaku !== self {
                let tmpTrack = newDanmaku.track
                let count = (trackInfo[tmpTrack] ?? 0) + 1
                trackInfo[tmpTrack] = count
            }
        }
        
        var track: Int?
        //弹幕数量最少的轨道
        var leastDanmakuTrack = 0
        var leastDanmakuCount = trackInfo[leastDanmakuTrack] ?? 0
        for i in 0..<trackCount {
            
            let idx: Int
            
            switch self.position {
            case .atTop:
                idx = i
            case .atBottom:
                idx = trackCount - i - 1
            }
            
            if let count = trackInfo[idx] {
                if count < leastDanmakuCount {
                    leastDanmakuTrack = idx
                    leastDanmakuCount = count
                }
            } else {
                //没有弹幕的轨道
                track = idx
                break
            }
        }
        
        if track == nil {
            switch context.layoutStyle {
            case .timely:
                track = leastDanmakuTrack
            case .nonOverlapping:
                //不重叠的布局风格，会忽略某些弹幕
                return false
            }
        }
        
        self.track = track!
        self.doResize(context)
        
        return flag
    }
    
    open override func doResize(_ context: DanmakuContext) {
        super.doResize(context)
        
        let trackHeight = self.trackHeight(context)
        var danmakuFrame = context.container.frame
        let canvasFrame = context.canvas.bounds
        danmakuFrame.origin = .init(x: (canvasFrame.width - danmakuFrame.width) / 2,
                                    y: (CGFloat(self.track) * trackHeight) + ((trackHeight - danmakuFrame.height) / 2))
        context.container.frame = danmakuFrame
    }
    
    open override func shouldMoveOutCanvas(_ context: DanmakuContext) -> Bool {
        if self.isPause {
            return false
        }
        
        let time = context.engineTime
        
        /// 重新恢复计时时，弹幕需要加上已经走过的时间，避免突然消失
        if let timePast = self.offsetTime {
            return abs(time - (self.appearTime + timePast)) > self.lifeTime
        } else {
            return abs(time - self.appearTime) > self.lifeTime
        }
        
    }
    
}

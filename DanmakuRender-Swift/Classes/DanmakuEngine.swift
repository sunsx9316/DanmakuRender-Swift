//
//  DanmakuEngine.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/2.
//

import Foundation

public class DanmakuEngine {
    
    /// 弹幕布局风格
    public enum LayoutStyle {
        /// 及时风格，有弹幕就发射
        case timely
        /// 倾向不重叠，可能会忽略部分弹幕
        case nonOverlapping
    }
    
    /// 弹幕画布
    public private(set) lazy var canvas = DanmakuCanvas()
    
    /// 弹幕布局风格
    public var layoutStyle = LayoutStyle.timely
    
    /// 当前时间
    public var time: TimeInterval {
        set {
            //fix 时间倒退导致滚动弹幕无效的问题
            self.activeContainers.forEach({ $0.isActive = false })
            
            self.clock.time = newValue
        }
        
        get {
            return self.clock.time + self.offsetTime
        }
    }
    
    /// 弹幕偏移时间
    public var offsetTime: TimeInterval {
        set {
            self.clock.offset = newValue
        }
        
        get {
            return self.clock.offset
        }
    }
    
    /// 弹幕速度
    public var speed: Double {
        set {
            self.clock.speed = newValue
        }
        
        get {
            return self.clock.speed
        }
    }
    
    /// 当前屏幕上所有的弹幕容器
    public var containers: [DanmakuContainerProtocol] {
        return self.activeContainers
    }
    
    /// 当前活跃的弹幕
    private(set) lazy var activeContainers = [DanmakuContainer]()
    
    /// 当前被移出屏幕的弹幕
    private(set) lazy var inactiveContainers = [DanmakuContainer]()
    
    /// 时钟
    private lazy var clock: Clock = {
        var clock = Clock()
        clock.delegate = self
        return clock
    }()
    
    /// ctx缓存key
    private static var ctxCacheKey = 0
    
    public init() {}
    
    deinit {
        AsyncDisplayQueue.cleanup()
        Transaction.cleanup()
    }
    
    /// 启动弹幕引擎
    public func start() {
        self.clock.start()
    }
    
    /// 停止弹幕引擎
    public func stop() {
        self.clock.stop()
        
        self.activeContainers.forEach({ $0.removeFromCanvas() })
        self.activeContainers.removeAll()
        self.inactiveContainers.removeAll()
    }
    
    /// 暂停弹幕引擎
    public func pause() {
        self.clock.pause()
    }
    
    /// 发射弹幕
    /// - Parameter danmaku: 弹幕
    public func send(_ danmaku: DanmakuProtocol) {
        let container: DanmakuContainer
        
        if let cacheContainer = self.inactiveContainers.first {
            container = cacheContainer
            container.danmaku = danmaku
            container.isActive = true
            self.inactiveContainers.removeFirst()
        } else {
            container = .init(danmaku: danmaku)
        }
        
        if container.danmaku.shouldAddToCanvas(self.context(with: container)) {
            self.activeContainers.append(container)
            self.canvas.add(container)
        } else {
            self.inactiveContainers.append(container)
        }
    }
    
    //MARK: Privte Method
    private func context(with container: DanmakuContainerProtocol) -> DanmakuContext {
        if let ctx = objc_getAssociatedObject(container, &DanmakuEngine.ctxCacheKey) as? DanmakuContext {
            return ctx
        }
        
        let ctx = DanmakuContext(engine: self, container: container)
        objc_setAssociatedObject(container, &DanmakuEngine.ctxCacheKey, ctx, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return ctx
    }
    
}

extension DanmakuEngine: ClockDelegate {
    func clock(_ clock: Clock, didChange time: TimeInterval) {
        
        for (idx, container) in self.activeContainers.enumerated().reversed() {
            let ctx = self.context(with: container)
            
            var isActive = container.isActive && !container.danmaku.shouldMoveOutCanvas(ctx)
            
            //移出屏幕
            if !isActive {
                container.danmaku.willMoveOutCanvas(ctx)
                container.removeFromCanvas()
                self.activeContainers.remove(at: idx)
                self.inactiveContainers.append(container)
            } else {
                if container.isNeedLayout {
                    container.danmaku.didLayout(ctx)
                    container.isNeedLayout = false
                }
                
                if container.isNeedRedraw {
                    container.redraw()
                    container.isNeedRedraw = false
                }
                
                //更新弹幕位置
                container.danmaku.update(context: ctx)
            }
        }
    }
}

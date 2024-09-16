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
    
    public var delegate: (any DanmakuEngineDelegate)?
    
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
    public func send(_ danmaku: BaseDanmaku) {
        let container: DanmakuContainer
        
        if let cacheContainer = self.inactiveContainers.first {
            container = cacheContainer
            container.danmaku = danmaku
            container.isActive = true
            self.inactiveContainers.removeFirst()
        } else {
            container = .init(danmaku: danmaku)
        }
        
        var shouldAddToCanvas = container.danmaku.shouldAddToCanvas(self.context(with: container))
        if let delegate = self.delegate {
            shouldAddToCanvas = delegate.shouldAddToCanvas(shouldAdd: shouldAddToCanvas, danmaku: container.danmaku, engine: self)
        }
        if shouldAddToCanvas {
            self.activeContainers.append(container)
            self.canvas.add(container)
        } else {
            self.inactiveContainers.append(container)
        }
    }
    
    /// 更新弹幕
    /// - Parameters:
    ///   - danmaku: 弹幕
    ///   - animateHandle: 动画句柄
    public func update(_ danmaku: BaseDanmaku, animateHandle: ((DRView) -> Void)? = nil) {
        if let container = activeContainers.first(where: { $0.danmaku === danmaku }) {
            container.isNeedsRedraw = true
            container.isNeedsLayout = true
            animateHandle?(container)
        }
    }
    
    //MARK: Privte Method
    private func context(with container: DanmakuContainer) -> DanmakuContext {
        if let ctx = container.context {
            return ctx
        }
        
        let ctx = DanmakuContext(engine: self, container: container)
        container.context = ctx
        return ctx
    }
    
}

extension DanmakuEngine: ClockDelegate {
    func clock(_ clock: Clock, didChange time: TimeInterval) {
        
        for (idx, container) in self.activeContainers.enumerated().reversed() {
            let ctx = self.context(with: container)
            
            let isActive = container.isActive && !container.danmaku.shouldMoveOutCanvas(ctx)
            
            //移出屏幕
            if !isActive {
                self.delegate?.willMoveOutCanvas(danmaku: container.danmaku, engine: self)
                container.removeFromCanvas()
                container.danmaku.moveOutFromCanvas(ctx)
                self.activeContainers.remove(at: idx)
                self.inactiveContainers.append(container)
            } else {
                
                if container.isNeedsLayout {
                    container.danmaku.doResize(ctx)
                    container.isNeedsLayout = false
                    self.delegate?.didLayout(danmaku: container.danmaku, engine: self)
                }
                
                if container.isNeedsRedraw {
                    container.redraw()
                    container.isNeedsRedraw = false
                }
                
                //更新弹幕位置
                container.danmaku.update(context: ctx)
                self.delegate?.update(danmaku: container.danmaku, engine: self)
            }
        }
    }
}

//
//  DanmakuProtocol.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation

/// 弹幕边缘
public enum DanmakuEffectStyle: Int, CaseIterable {
    /// 没有效果
    case none = 0
    /// 描边
    case stroke
    /// 阴影
    case shadow
    /// 发光
    case glow
}


/// 弹幕上下文
public class DanmakuContext {
    
    public var layoutStyle: DanmakuEngine.LayoutStyle {
        return self.engine.layoutStyle
    }
    
    /// 弹幕所在画布
    public var canvas: DRView {
        return self.engine.canvas
    }
    
    /// 弹幕所属容器
    public let container: DanmakuContainerProtocol
    
    /// 当前活跃的弹幕容器
    public var activeContainers: [DanmakuContainerProtocol] {
        return self.engine.activeContainers
    }
    
    /// 当前不活跃的弹幕容器
    public var inactiveContainers: [DanmakuContainerProtocol] {
        return self.engine.inactiveContainers
    }
    
    /// 引擎时间
    public var engineTime: TimeInterval {
        return self.engine.time
    }
    
    public let engine: DanmakuEngine
    
    init(engine: DanmakuEngine, container: DanmakuContainerProtocol) {
        self.engine = engine
        self.container = container
    }
}

public protocol DanmakuEngineDelegate: AnyObject {
    
    /// 弹幕是否应该被添加到画布上
    /// - Parameters:
    ///   - shouldAdd: 原始实现
    ///   - danmaku: 弹幕对象
    /// - Returns: 是否应该被添加到画布上
    func shouldAddToCanvas(shouldAdd: Bool, danmaku: BaseDanmaku, engine: DanmakuEngine) -> Bool
    
    /// 容器完成布局
    /// - Parameter danmaku: 弹幕对象
    func didLayout(danmaku: BaseDanmaku, engine: DanmakuEngine)
    
    /// 时钟更新回调
    /// - Parameter danmaku: 弹幕对象
    func update(danmaku: BaseDanmaku, engine: DanmakuEngine)
    
    /// 即将被移出画布
    /// - Parameter danmaku: 弹幕对象
    func willMoveOutCanvas(danmaku: BaseDanmaku, engine: DanmakuEngine)
}

public extension DanmakuEngineDelegate {
    func shouldAddToCanvas(shouldAdd: Bool, danmaku: BaseDanmaku, engine: DanmakuEngine) -> Bool {
        return shouldAdd
    }
    
    func didLayout(danmaku: BaseDanmaku, engine: DanmakuEngine) {
        
    }
    
    func update(danmaku: BaseDanmaku, engine: DanmakuEngine) {
        
    }
    
    func willMoveOutCanvas(danmaku: BaseDanmaku, engine: DanmakuEngine) {
        
    }
}

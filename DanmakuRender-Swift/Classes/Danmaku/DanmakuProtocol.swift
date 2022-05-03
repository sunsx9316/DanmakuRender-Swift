//
//  DanmakuProtocol.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation

/// 弹幕边缘
public enum DanmakuEffectStyle {
    /// 没有效果
    case none
    /// 描边
    case stroke
    /// 阴影
    case shadow
    /// 发光
    case glow
}


/// 弹幕上下文
public struct DanmakuContext {
    
    /// 弹幕所在画布
    public let canvas: DRView
    
    /// 弹幕所属容器
    public var container: DanmakuContainerProtocol
    
    /// 当前活跃的弹幕容器
    public let activeContainers: [DanmakuContainerProtocol]
    
    /// 当前不活跃的弹幕容器
    public let inactiveContainers: [DanmakuContainerProtocol]
    
    /// 引擎速度
    public let engineSpeed: Double
    
    /// 引擎时间
    public let engineTime: TimeInterval
    
}

/// 弹幕协议
public protocol DanmakuProtocol: AsyncLayerDisplayTask {
    
    var isNeedsDisplay: Bool { get set }
    
    /// 弹幕尺寸
    var size: CGSize { get }
    
    /// 即将被添加到画布
    /// - Parameter context: 上下文
    func willAddToCanvas(_ context: DanmakuContext)
    
    /// 需要重新布局
    /// - Parameter context: 上下文
    func didLayout(_ context: DanmakuContext)
    
    /// 更新位置
    /// - Parameter context: 上下文
    func update(context: DanmakuContext)
    
    /// 即将被移除
    /// - Parameter context: 上下文
    func willMoveOutCanvas(_ context: DanmakuContext)
    
    /// 是否应该被移出画布
    /// - Parameter context: 上下文
    /// - Returns: 返回true，则被移除
    func shouldMoveOutCanvas(_ context: DanmakuContext) -> Bool
}

public extension DanmakuProtocol {
    
    func willAddToCanvas(_ context: DanmakuContext) {
        
    }
    
    func willMoveOutCanvas(_ context: DanmakuContext) {
        
    }
}

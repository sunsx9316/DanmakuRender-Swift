//
//  BaseDanmaku.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/1.
//

import Foundation

/// 基础弹幕类
open class BaseDanmaku: AsyncLayerDisplayTask {
    
    /// 弹幕出现时间
    open var appearTime: TimeInterval = 0
    
    /// 弹幕尺寸
    open var size = CGSize.zero
    
    /// 弹幕边缘效果
    open var effectStyle: DanmakuEffectStyle {
        didSet {
            self.isNeedsRedraw = true
            self.isNeedsLayout = true
            self._attributes = nil
        }
    }
    
    /// 弹幕字体颜色
    open var textColor: DRColor {
        didSet {
            self.isNeedsRedraw = true
            self._attributes = nil
        }
    }
    
    /// 弹幕字体
    open var font: DRFont {
        didSet {
            self.isNeedsRedraw = true
            self.isNeedsLayout = true
            self._attributes = nil
        }
    }
    
    /// 弹幕文字
    open var text: String {
        didSet {
            self.isNeedsRedraw = true
            self.isNeedsLayout = true
            self._attributes = nil
        }
    }
    
    /// 是否需要重绘
    open var isNeedsRedraw = true
    
    /// 是否需要重新布局
    open var isNeedsLayout = true
    
    /// 暂停的状态
    open var isPause = false {
        didSet {
            if let context = self.contextCallBack?() {
                if self.isPause {
                    if self.pauseTime == nil {
                        self.pauseTime = context.engineTime
                    }
                } else {
                    if let pauseTime = self.pauseTime {
                        self.offsetTime = (self.offsetTime ?? 0) + (context.engineTime - pauseTime)
                        self.pauseTime = nil
                    }
                }
            }
        }
    }
    
    /// 边缘颜色 由字体颜色的亮度决定
    open var effectColor: DRColor {
        if self.textColor.brightness > 0.6 {
            return DRColor.black
        } else {
            return DRColor.white
        }
    }
    
    open var attributes: [NSAttributedString.Key: Any] {
        if let _attributes = self._attributes {
            return _attributes
        }
        
        let attributes = self.createAttributes()
        self._attributes = attributes
        return attributes
    }
    
    /// 获取上下文
    var contextCallBack: (() -> DanmakuContext?)?
    
    
    /// 所在轨道
    var track = 0
    
    /// 最小轨道数量
    let minTrackCount = 1
    
    private var _attributes: [NSAttributedString.Key: Any]?
    
    /// 被暂停时的时间戳
    private(set) var pauseTime: TimeInterval?
    
    /// 弹幕偏移时间
    private(set) var offsetTime: TimeInterval?
    
    
    /// 初始化
    /// - Parameters:
    ///   - text: 文字
    ///   - textColor: 文字颜色
    ///   - font: 字体大小
    ///   - effectStyle: 边缘风格
    public init(text: String,
                textColor: DRColor,
                font: DRFont,
                effectStyle: DanmakuEffectStyle) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.effectStyle = effectStyle
    }
    
    /// 轨道高度
    func trackHeight(_ context: DanmakuContext) -> CGFloat {
        return (context.container.frame.height == 0 ? 24 : context.container.frame.height) + 6
    }
    
    open func shouldAddToCanvas(_ context: DanmakuContext) -> Bool {
        //未指定显示时间，则将添加到屏幕的时间作为显示时间
        if self.appearTime == 0 {
            self.appearTime = context.engineTime
        }
        
        self.doResize(context)
        
        return true
    }
    
    
    /// 时钟回调
    /// - Parameter context: 上下文
    open func update(context: DanmakuContext) {
        
    }
    
    /// 是否应该被移除出屏幕
    /// - Parameter context: 上下文
    /// - Returns: 是否应该被移除出屏幕
    open func shouldMoveOutCanvas(_ context: DanmakuContext) -> Bool {
        return false
    }
    
    /// 即将被移除出屏幕回调
    /// - Parameter context: 上下文
    open func moveOutFromCanvas(_ context: DanmakuContext) {
        self.isPause = false
        self.pauseTime = nil
        self.offsetTime = nil
        self.contextCallBack = nil
    }
    
    /// 绘制回调
    /// - Parameters:
    ///   - context: 上下文
    ///   - size: 弹幕尺寸
    ///   - isCancelled: 调用则取消绘制
    open func draw(_ context: CGContext, size: CGSize, isCancelled: @escaping (() -> Bool)) {
        if isCancelled() {
            return
        }
        
        let attributes = self.attributes
        let attributedString = NSAttributedString(string: self.text,
                                                  attributes: attributes)
        
        let textSize = attributedString.size()
        let point = CGPoint(x: 1, y: (size.height - textSize.height) / 2)
        
        if self.effectStyle == .stroke {
            
            //设置strokeWidth效果不理想，通过此方式绘制外描边
            context.setLineWidth(3)
            context.setLineJoin(.round)
            context.setStrokeColor(self.effectColor.cgColor)
            context.setTextDrawingMode(.stroke)
            
            var strokeAttributs = attributes
            strokeAttributs[.foregroundColor] = self.effectColor
            let strokeAttributedString = NSAttributedString(string: self.text, attributes: strokeAttributs)
            
            strokeAttributedString.draw(at: point)
            
            //绘制文字
            context.setFillColor(self.textColor.cgColor)
            context.setTextDrawingMode(.fill)
            attributedString.draw(at: point)
        } else {
            
            attributedString.draw(at: point)
        }
    }
    
    /// 弹幕尺寸
    /// - Parameter oldSize: 旧尺寸
    /// - Returns: 新尺寸
    open func newDanmakuSize(_ oldSize: CGSize) -> CGSize {
        return oldSize
    }
    
    /// 布局完成回调
    /// - Parameter context: 上下文
    func doResize(_ context: DanmakuContext) {
        let attributeStr = NSAttributedString(string: self.text, attributes: self.attributes)
        let textSize = attributeStr.size()
        
        let padding: CGSize
        switch effectStyle {
        case .none, .shadow, .glow:
            padding = .init(width: 3, height: 0)
        case .stroke:
            padding = .init(width: 5, height: 0)
        }
        
        self.size = self.newDanmakuSize(CGSize(width: textSize.width + padding.width,
                                            height: textSize.height + padding.height))
        
        if context.container.frame.size != self.size {
            context.container.frame.size = self.size
        }
    }
    
    //MARK: - Private Method
    /// 重新生成富文本
    private func createAttributes() -> [NSAttributedString.Key: Any] {
        func shadow(with color: DRColor, shadowColor: DRColor) -> NSShadow {
            let shadow = NSShadow()
            #if os(macOS)
            shadow.shadowOffset = .init(width: 1, height: -1)
            #else
            shadow.shadowOffset = .init(width: 1, height: 1)
            #endif
            shadow.shadowColor = shadowColor
            return shadow
        }
        
        var attributed = [NSAttributedString.Key: Any]()
        attributed[.font] = self.font
        attributed[.foregroundColor] = self.textColor

        switch effectStyle {
        case .none:
            break
        case .stroke:
            break
        case .shadow:
            if !text.isEmpty {
                let shadow = shadow(with: self.textColor, shadowColor: self.effectColor)
                attributed[.shadow] = shadow
            }
        case .glow:
            if !text.isEmpty {
                let shadow = shadow(with: self.textColor, shadowColor: self.effectColor)
                shadow.shadowBlurRadius = 3
                attributed[.shadow] = shadow
            }
        }
        
        return attributed
    }
    
}

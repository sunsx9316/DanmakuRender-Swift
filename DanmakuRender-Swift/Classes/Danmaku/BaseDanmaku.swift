//
//  BaseDanmaku.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/1.
//

import Foundation

/// 基础弹幕类
open class BaseDanmaku: DanmakuProtocol {
    
    /// 弹幕出现时间
    open var appearTime: TimeInterval = 0
    
    /// 弹幕尺寸
    public var size = CGSize.zero
    
    /// 弹幕边缘效果
    public var effectStyle: DanmakuEffectStyle {
        didSet {
            self.resetAttributedString()
            self.isNeedsDisplay = true
        }
    }
    
    /// 弹幕字体颜色
    public var textColor: DRColor {
        didSet {
            self.resetAttributedString()
            self.isNeedsDisplay = true
        }
    }
    
    /// 弹幕字体
    public var font: DRFont {
        didSet {
            self.resetAttributedString()
            self.isNeedsDisplay = true
        }
    }
    
    /// 弹幕文字
    public var text: String {
        didSet {
            self.resetAttributedString()
            self.isNeedsDisplay = true
        }
    }
    
    /// 是否需要重绘
    public var isNeedsDisplay = false
    
    /// 富文本，便于绘制
    private var attributedString: NSAttributedString!
    
    /// 边缘颜色 由字体颜色的亮度决定
    private var effectColor: DRColor {
        if self.textColor.brightness > 0.6 {
            return DRColor.black
        } else {
            return DRColor.white
        }
    }
    
    /// 所在轨道
    var track = 0
    
    /// 最小轨道数量
    let minTrackCount = 1
    
    
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
        
        self.resetAttributedString()
    }
    
    /// 轨道高度
    func trackHeight(_ context: DanmakuContext) -> CGFloat {
        return (context.container.frame.height == 0 ? 24 : context.container.frame.height) + 6
    }
    
    public func shouldAddToCanvas(_ context: DanmakuContext) -> Bool {
        //未指定显示时间，则将添加到屏幕的时间作为显示时间
        if appearTime == 0 {
            self.appearTime = context.engineTime
        }
        
        return true
    }
    
    public func update(context: DanmakuContext) {
        
    }
    
    public func shouldMoveOutCanvas(_ context: DanmakuContext) -> Bool {
        return false
    }
    
    public func didLayout(_ context: DanmakuContext) {
        
    }
    
    public func draw(_ context: CGContext, size: CGSize, isCancelled: @escaping (() -> Bool)) {
        if isCancelled() {
            return
        }
        
        let textSize = self.attributedString.size()
        let point = CGPoint(x: (size.width - textSize.width) / 2,
                            y: (size.height - textSize.height) / 2)
        
        if self.effectStyle == .stroke {
            //绘制描边
            context.setLineWidth(1)
            context.setLineJoin(.round)
            context.setStrokeColor(self.effectColor.cgColor)
            context.setTextDrawingMode(.stroke)

            (self.text as NSString).draw(at: point, withAttributes: [.font: self.font])
            
            //绘制文字
            context.setFillColor(self.textColor.cgColor)
            context.setTextDrawingMode(.fill)
            self.attributedString.draw(at: point)
        } else {
            self.attributedString.draw(at: point)
        }
    }
    
    //MARK: - Private Method
    /// 重新生成富文本
    private func resetAttributedString() {
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
        
        let mAttributedString = NSMutableAttributedString(string: self.text,
                                                          attributes: [.font: self.font, .foregroundColor: self.textColor])
        let padding: CGSize
        switch effectStyle {
        case .none:
            padding = .zero
        case .stroke:
            padding = .init(width: 5, height: 0)
        case .shadow:
            let shadow = shadow(with: textColor, shadowColor: self.effectColor)
            mAttributedString.addAttribute(.shadow, value: shadow, range: .init(location: 0, length: text.count))
            padding = .zero
        case .glow:
            let shadow = shadow(with: textColor, shadowColor: self.effectColor)
            shadow.shadowBlurRadius = 3
            mAttributedString.addAttribute(.shadow, value: shadow, range: .init(location: 0, length: text.count))
            padding = .zero
        }
        
        self.attributedString = mAttributedString
        
        let textSize = mAttributedString.size()
        self.size = .init(width: textSize.width + padding.width,
                          height: textSize.height + padding.height)
    }
    
    
}

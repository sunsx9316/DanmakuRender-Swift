//
//  DanmakuContainer.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

public protocol DanmakuContainerProtocol: AnyObject {
    
    var frame: CGRect { get set }
    
    var danmaku: BaseDanmaku { get }
 
}

/// 弹幕容器
class DanmakuContainer: DRView, DanmakuContainerProtocol {
    
    /// 上下文
    var context: DanmakuContext?
    
    /// 缩放因子
    var scaleFactor: CGFloat {
        get {
            self.displayLayer.contentsScale
        }
        
        set {
            self.displayLayer.contentsScale = newValue
        }
    }
    
    /// 弹幕
    var danmaku: BaseDanmaku {
        didSet {
            self.danmakuChange()
        }
    }
    
    /// 是否需要重新布局
    var isNeedsLayout: Bool {
        get {
            return self.danmaku.isNeedsLayout
        }
        
        set {
            self.danmaku.isNeedsLayout = newValue
        }
    }
    
    /// 是否需要重新绘制
    var isNeedsRedraw: Bool {
        get {
            return self.danmaku.isNeedsRedraw
        }
        
        set {
            self.danmaku.isNeedsRedraw = newValue
        }
    }
    
    /// 是否为激活状态，false时会被移出屏幕
    var isActive = true
    
    init(danmaku: BaseDanmaku) {
        self.danmaku = danmaku
        super.init(frame: .zero)
        self.setupInit()
        self.danmakuChange()
    }
    
    private lazy var displayLayer: AsyncDisplayLayer = {
        let layer = AsyncDisplayLayer()
        layer.asyncLayerDelegate = self
        layer.contentsGravity = CALayerContentsGravity.left
        return layer
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 将自己从画布中移除
    func removeFromCanvas() {
        self.removeFromSuperview()
    }
    
    
    private func setupInit() {
#if os(macOS)
        self.wantsLayer = true
        self.layer?.backgroundColor = DRColor.clear.cgColor
        self.layer?.addSublayer(self.displayLayer)
#else
        self.backgroundColor = DRColor.clear
        self.layer.addSublayer(self.displayLayer)
        self.isUserInteractionEnabled = true
#endif
        
    }
    
#if os(iOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        self.displayLayer.frame = self.bounds
    }
    
#else
    override func layout() {
        super.layout()
        self.displayLayer.frame = self.bounds
    }
#endif
    
    private func danmakuChange() {
        self.danmaku.contextCallBack = { [weak self] in
            self?.context
        }
        
        self.displayLayer.contents = nil
        self.isNeedsLayout = true
        self.isNeedsRedraw = true
    }
    
    /// 提交绘制任务
    func redraw() {
        let tran = Transaction(self, selector: #selector(contentsNeedUpdated))
        tran.commit()
    }
    
    //MARK: Private Method
    @objc private func contentsNeedUpdated() {
        self.displayLayer.setNeedsDisplay()
    }
}

extension DanmakuContainer: AsyncLayerDelegate {
    func newAsyncDisplayTask() -> AsyncLayerDisplayTask? {
        return self.danmaku
    }
}

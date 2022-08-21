//
//  DanmakuContainer.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation

public protocol DanmakuContainerProtocol: AnyObject {
    
    var frame: CGRect { get set }
    
    var danmaku: DanmakuProtocol { get }
 
}

/// 弹幕容器
class DanmakuContainer: AsyncDisplayLayer, DanmakuContainerProtocol {
    
    /// 弹幕
    var danmaku: DanmakuProtocol {
        didSet {
            self.danmakuChange()
        }
    }
    
    /// 是否需要重新布局
    var isNeedLayout = false
    
    /// 是否需要重新绘制
    var isNeedRedraw: Bool {
        get {
            return self.danmaku.isNeedsDisplay
        }
        
        set {
            self.danmaku.isNeedsDisplay = newValue
        }
    }
    
    /// 是否为激活状态，false时会被移出屏幕
    var isActive = true
    
    init(danmaku: DanmakuProtocol) {
        self.danmaku = danmaku
        super.init()
        self.setupInit()
        self.danmakuChange()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 将自己从画布中移除
    func removeFromCanvas() {
        self.removeFromSuperlayer()
    }
    
    private func setupInit() {
        self.asyncLayerDelegate = self
        self.contentsGravity = CALayerContentsGravity.left
    }
    
    private func danmakuChange() {
        self.frame.size = self.danmaku.size
        self.contents = nil
        self.redraw()
    }
    
    /// 提交绘制任务
    func redraw() {
        let tran = Transaction(self, selector: #selector(contentsNeedUpdated))
        tran.commit()
    }
    
    //MARK: Private Method
    @objc private func contentsNeedUpdated() {
        self.setNeedsDisplay()
    }
}

extension DanmakuContainer: AsyncLayerDelegate {
    func newAsyncDisplayTask() -> AsyncLayerDisplayTask? {
        return self.danmaku
    }
    
}

//
//  AsyncDisplayLayer.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation

protocol AsyncLayerDelegate: AnyObject {
    func newAsyncDisplayTask() -> AsyncLayerDisplayTask?
}

/// 异步绘制任务
public protocol AsyncLayerDisplayTask {
    
    /// 异步绘制回调，需要注意线程安全问题
    /// - Parameters:
    ///   - context: 上下文
    ///   - size: 绘制区域
    ///   - isCancelled: 绘制是否被取消
    func draw(_ context: CGContext, size: CGSize, isCancelled: @escaping(() -> Bool))
}

/// 异步绘制layer
class AsyncDisplayLayer: CALayer {
    
    /// 计数器，用于判断当前是否有新的任务
    private lazy var sentinel = Sentinel()
    
    weak var asyncLayerDelegate: AsyncLayerDelegate?
    
    deinit {
        sentinel.increase()
    }
    
    override func setNeedsDisplay() {
        sentinel.increase()
        super.setNeedsDisplay()
    }
    
    override func display() {
        super.contents = super.contents
        self._display()
    }
    
    override func action(forKey event: String) -> CAAction? {
        return nil
    }
    
    private func _display() {
        guard let task = self.asyncLayerDelegate?.newAsyncDisplayTask() else {
            self.contents = nil
            return
        }
        
        
        let value = sentinel.value

        weak var weakSelf = self
        
        @discardableResult func isCancelled() -> Bool {
            
            guard let self = weakSelf else { return true }
            
            return value != self.sentinel.value
        }
        
        let scale = self.contentsScale
        let size = self.bounds.size
        let opaque = self.isOpaque
        
        let backgroundColor: CGColor
        
        if let aBackgroundColor = self.backgroundColor, opaque, aBackgroundColor.alpha >= 1 {
            backgroundColor = aBackgroundColor
        } else {
            backgroundColor = DRColor.white.cgColor
        }
        
        if size.width < 1 || size.height < 1 {
            let image = self.contents as? DRImage
            self.contents = nil
            if image != nil {
                DispatchQueue.global(qos: .background).async {
                    _ = image.debugDescription
                }
            }
            return
        }
        
        AsyncDisplayQueue.addOperation { [weak self] in
            guard let self = self else {
                isCancelled()
                return
            }
            
            let img = self.drawImage(size, opaque: opaque, scale: scale) { context in
                
                if opaque {
                    
                    context?.saveGState()
                    
                    context?.setFillColor(backgroundColor)
                    context?.addRect(.init(x: 0, y: 0, width: size.width, height: size.height))
                    context?.fillPath()
                    
                    context?.restoreGState()
                }
                
                if isCancelled() {
                    return false
                }
                
                if let context = context {
                    task.draw(context, size: size, isCancelled: isCancelled)
                }
                
                if isCancelled() {
                    return false
                }
                
                return true
            }
            
            if isCancelled() {
                return
            }
            
            DispatchQueue.main.async {
                self.contents = img
            }
        }
        
    }
    
    private func drawImage(_ size: CGSize, opaque: Bool, scale: CGFloat, block: @escaping((CGContext?) -> Bool)) -> Any? {
        #if os(iOS)
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let success = block(UIGraphicsGetCurrentContext())
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return success ? img?.cgImage : nil
        #else
        
        let img = DRImage(size: size, flipped: false) { dstRect in
            return block(NSGraphicsContext.current?.cgContext)
        }
        
        return img.layerContents(forContentsScale: scale)
        #endif
    }
}

//
//  DanmakuCanvas.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/2.
//

import Foundation

public class DanmakuCanvas: DRView {
    
    private var scale: CGFloat {
#if os(iOS)
        return UIScreen.main.scale
#else
        return self.window?.backingScaleFactor ?? 1
#endif
    }
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        self.setupInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupInit()
    }
    
#if os(macOS)
    public override var isFlipped: Bool {
        return true
    }
    
    public override func layout() {
        super.layout()
        
        self.forEachContainer { container in
            container.isNeedsLayout = true
        }
    }
    
#else
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.forEachContainer { container in
            container.isNeedsLayout = true
        }
    }
#endif
    
    /// 添加弹幕容器到层级中
    /// - Parameter container: 容器
    func add(_ container: DanmakuContainer) {
        container.scaleFactor = self.scale
        self.addSubview(container)
    }
    
    //MARK: Private Method
    private func setupInit() {
#if os(macOS)
        self.wantsLayer = true
        self.layer?.backgroundColor = DRColor.clear.cgColor
#else
        self.backgroundColor = DRColor.clear
#endif
    }
    
    private func forEachContainer(_ body: (DanmakuContainer) -> Void) {
        for container in self.subviews {
            if let container = container as? DanmakuContainer {
                body(container)
            }
        }
    }
    
}

#if os(macOS)
extension DanmakuCanvas: NSViewLayerContentScaleDelegate {
    public func layer(_ layer: CALayer, shouldInheritContentsScale newScale: CGFloat, from window: NSWindow) -> Bool {
        self.forEachContainer { container in
            container.scaleFactor = newScale
            container.isNeedRedraw = true
        }
        
        return true
    }
}
#endif

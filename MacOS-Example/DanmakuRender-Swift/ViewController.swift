//
//  ViewController.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 04/30/2022.
//  Copyright (c) 2022 jimhuang. All rights reserved.
//

import Cocoa
import DanmakuRender

class ViewController: NSViewController {
    
    private lazy var danmakuEngine: DanmakuEngine = {
        let danmakuEngine = DanmakuEngine()
        return danmakuEngine
    }()
    
    private var sendTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.highlightColor.cgColor
        self.view.addSubview(self.danmakuEngine.canvas)
        
        self.danmakuEngine.start()
        
        self.sendTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }

            var str = "测试弹幕"
            for _ in 0..<Int.random(in: 0...4) {
                str += "测试弹幕"
            }

            let danamu = ScrollDanmaku(text: str, textColor: .white, font: .systemFont(ofSize: 14), effectStyle: .shadow, direction: .toRight)
            self.danmakuEngine.send(danamu)
        })
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        self.danmakuEngine.canvas.frame = self.view.bounds
    }
    
    
}


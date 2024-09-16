//
//  ViewController.swift
//  iOS-Example
//
//  Created by jimhuang on 2022/4/30.
//

import UIKit
import DanmakuRender

var increaseCount = 0

class ViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    private lazy var danmakuEngine: DanmakuEngine = {
        let danmakuEngine = DanmakuEngine()
        return danmakuEngine
    }()
    
    private var sendTimer: Timer?
    
    @IBOutlet weak var canvas: UIView!
    
    private var context = SettingViewController.Context(fontSize: 16, speed: 1, offset: 0, danmakuType: .scroll)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.lightGray
        self.canvas.addSubview(self.danmakuEngine.canvas)
        
        self.danmakuEngine.start()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.danmakuEngine.canvas.frame = self.canvas.bounds
    }

    
    @IBAction func onSettingButonTouch(_ sender: UIButton) {
        let vc = SettingViewController(context: self.context)
        
        vc.contextChangeCallBack = { [weak self] ctx in
            guard let self = self else { return }
            
            if ctx.speed != self.context.speed {
                self.danmakuEngine.speed = ctx.speed
            }
            
            if ctx.offset != self.context.offset {
                self.danmakuEngine.offsetTime = ctx.offset
            }
            
            if ctx.fontSize != self.context.fontSize {
                let font = UIFont.systemFont(ofSize: ctx.fontSize)
                for con in self.danmakuEngine.containers {
                    con.danmaku.font = font
                }
            }
            
            self.context = ctx
        }
        
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.sourceView = sender
        vc.presentationController?.delegate = self
        self.present(vc, animated: true)
    }
    
    @IBAction func onClickSendDanmakuButton(_ sender: UIButton) {
        switch self.context.danmakuType {
        case .scroll:
            let danamu = ScrollDanmaku(text: "滚动弹幕 \(increaseCount)", textColor: .white, font: .systemFont(ofSize: self.context.fontSize), effectStyle: .stroke, direction: .toRight)
            self.danmakuEngine.send(danamu)
        case .float:
            let danamu = FloatDanmaku(text: "浮动弹幕 \(increaseCount)", textColor: .white, font: .systemFont(ofSize: self.context.fontSize), effectStyle: .stroke, position: .atBottom, lifeTime: 2)
            self.danmakuEngine.send(danamu)
        }
        increaseCount += 1
    }
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}


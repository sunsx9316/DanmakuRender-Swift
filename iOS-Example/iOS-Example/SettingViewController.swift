//
//  SettingViewController.swift
//  iOS-Example
//
//  Created by jimhuang on 2022/5/3.
//

import UIKit
import DanmakuRender


class SettingViewController: UIViewController {
    
    enum DanmakuType {
        case scroll
        case float
        
        var title: String {
            switch self {
            case .scroll:
                return "选择弹幕样式：滚动"
            case .float:
                return "选择弹幕样式：浮动"
            }
        }
    }
    
    struct Context {
        var fontSize: CGFloat
        var speed: Double
        var offset: TimeInterval
        var danmakuType: DanmakuType
    }
    
    weak var engine: DanmakuEngine?
    
    private var context: Context
 
    @IBOutlet weak var fontSizeSlider: UISlider!
    
    @IBOutlet weak var danmakuSpeedSlider: UISlider!
    
    @IBOutlet weak var offsetTimeLabel: UILabel!
    
    var contextChangeCallBack: ((Context) -> Void)?
    
    @IBOutlet weak var danmakuTypeButton: UIButton!
    
    @IBOutlet weak var offsetStpper: UIStepper!
    
    
    init(context: Context) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fontSizeSlider.value = Float(self.context.fontSize)
        self.danmakuSpeedSlider.value = Float(self.context.speed)
        self.offsetTimeLabel.text = "弹幕偏移: \(self.context.offset)"
        self.danmakuTypeButton.setTitle(self.context.danmakuType.title, for: .normal)
        self.offsetStpper.value = self.context.offset
    }
    
    @IBAction func onFontSizeChange(_ sender: UISlider) {
        self.context.fontSize = CGFloat(sender.value)
        self.contextChangeCallBack?(self.context)
    }
    
    @IBAction func onSpeedChange(_ sender: UISlider) {
        self.context.speed = CGFloat(sender.value)
        self.contextChangeCallBack?(self.context)
    }
    
    @IBAction func onTimeOffsetChange(_ sender: UIStepper) {
        self.offsetTimeLabel.text = "弹幕偏移: \(self.context.offset)"
        self.context.offset = TimeInterval(sender.value)
        self.contextChangeCallBack?(self.context)
    }
    
    @IBAction func onDanmakuTypeChange(_ sender: UIButton) {
        let ac = UIAlertController(title: "提示", message: "选择弹幕样式", preferredStyle: .actionSheet)
        ac.addAction(.init(title: "滚动", style: .default, handler: { _ in
            self.context.danmakuType = .scroll
            self.danmakuTypeButton.setTitle(self.context.danmakuType.title, for: .normal)
            self.contextChangeCallBack?(self.context)
        }))
        
        ac.addAction(.init(title: "浮动", style: .default, handler: { _ in
            self.context.danmakuType = .float
            self.danmakuTypeButton.setTitle(self.context.danmakuType.title, for: .normal)
            self.contextChangeCallBack?(self.context)
        }))
        
        ac.addAction(.init(title: "取消", style: .cancel, handler: { _ in
            
        }))
        
        self.present(ac, animated: true)
    }
}

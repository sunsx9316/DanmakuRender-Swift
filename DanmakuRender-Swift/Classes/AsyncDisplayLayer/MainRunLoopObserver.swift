//
//  MainRunLoopObserver.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/1.
//

import Foundation

class MainRunLoopObserver {
    
    private var obs: CFRunLoopObserver?
    
    func addObserver(activity: CFRunLoopActivity, order: CFIndex, callBack: @escaping ((CFRunLoopObserver?, CFRunLoopActivity) -> Void)) {
        let runloop = CFRunLoopGetMain()
        let obs = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activity.rawValue, true, 0xFFFFFF, callBack)
        self.obs = obs
        CFRunLoopAddObserver(runloop, obs, .commonModes)
    }
    
    deinit {
        if let obs = self.obs {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), obs, .commonModes)
        }
    }
}

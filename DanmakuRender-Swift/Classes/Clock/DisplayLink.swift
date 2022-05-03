//
//  DisplayLink.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation

#if os(macOS)
import CoreVideo
class DisplayLink {
    
    private var displayLink: CVDisplayLink!
    
    private weak var target: AnyObject?
    
    private let selector: Selector
    
    init(_ target: AnyObject, selector: Selector) {
        
        self.target = target
        self.selector = selector
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputHandler(displayLink) { [weak self] link, inNow, inOutputTime, flagsIn, flagsOut in
            
            guard let self = self else {
                return kCVReturnError
            }
            
            DispatchQueue.main.async {
                _ = self.target?.perform(self.selector)                
            }
            return kCVReturnSuccess
        }
    }
    
    deinit {
        CVDisplayLinkStop(self.displayLink)
    }
    
    func resume() {
        if CVDisplayLinkIsRunning(self.displayLink) {
            return
        }
        
        CVDisplayLinkStart(self.displayLink)
    }
    
    func pause() {
        if !CVDisplayLinkIsRunning(self.displayLink) {
            return
        }
        
        CVDisplayLinkStop(self.displayLink)
    }
}
#else
import UIKit

class DisplayLink {
    
    private var displayLink: CADisplayLink!
    
    private var isRunning = false
    
    init(_ target: AnyObject, selector: Selector) {
        self.displayLink = .init(target: target, selector: selector)
    }
    
    deinit {
        self.displayLink.invalidate()
    }
    
    func resume() {
        if isRunning {
            return
        }
        isRunning = true
        self.displayLink.add(to: .main, forMode: .common)
    }
    
    func pause() {
        if !isRunning {
            return
        }
        isRunning = false
        self.displayLink.remove(from: .main, forMode: .common)
    }
}

#endif

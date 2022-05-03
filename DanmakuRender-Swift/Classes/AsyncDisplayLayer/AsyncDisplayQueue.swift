//
//  AsyncDisplayQueue.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/1.
//

import Foundation

/// 异步队列 用于控制并发数
class AsyncDisplayQueue {
    
    private static var operationQueue: OperationQueue?
    
    static func addOperation(_ block: @escaping(() -> Void)) {
        var operationQueue = self.operationQueue
        
        if operationQueue == nil {
            operationQueue = .init()
            let count = min(max(ProcessInfo.processInfo.activeProcessorCount, 1), 16)
            operationQueue?.maxConcurrentOperationCount = count
        }
        operationQueue?.addOperation(block)
    }
    
    static func cleanup() {
        operationQueue = nil
    }
}

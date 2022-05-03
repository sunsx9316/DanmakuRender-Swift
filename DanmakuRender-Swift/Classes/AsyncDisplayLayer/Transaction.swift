//
//  Transaction.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/1.
//

import Foundation

class Sentinel {
    private(set) var value: Int32 = 0
    
    @discardableResult func increase() -> Int32 {
        return OSAtomicIncrement32(&self.value)
    }
}


/// 用于将事务统一提交到runloop
class Transaction: Equatable, Hashable {
    
    fileprivate weak var target: AnyObject?
    
    fileprivate let selector: Selector
    
    @Atomic static fileprivate var _transaction: Set<Transaction>?
    
    static private var _runLoopObserver: MainRunLoopObserver?
    
    init(_ target: AnyObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.target === rhs.target && lhs.selector == rhs.selector
    }
    
    func hash(into hasher: inout Hasher) {
        if let target = target {
            let point = Unmanaged<AnyObject>.passUnretained(target).toOpaque()
            hasher.combine(point)
        }
        
        hasher.combine(selector)
    }
    
    /// 提交事务
    func commit() {
        Transaction.add(self)
    }
    
    /// 添加事务
    /// - Parameter transaction: 事务
    private static func add(_ transaction: Transaction) {
        
        var transactions = _transaction
        if transactions == nil {
            transactions = .init()
            _runLoopObserver = .init()
            _runLoopObserver?.addObserver(activity: [.beforeWaiting, .exit], order: 0xFFFFFF, callBack: { observer, activity in
                
                guard let set = Transaction._transaction, !set.isEmpty else {
                    return
                }
                
                for tran in set {
                    _ = tran.target?.perform(tran.selector)
                }
                
                Transaction._transaction = .init()
            })
        }
        
        transactions?.insert(transaction)
        _transaction = transactions
    }
    
    static func cleanup() {
        _transaction = nil
        _runLoopObserver = nil
    }
}

//
//  DisplayLinkProtocol.swift
//  DanmakuRender-Swift
//
//  定时器抽象协议，用于 Clock 解耦具体的定时器实现。
//  支持 CADisplayLink（前台 vsync）和 DispatchSourceTimer（后台可用）。
//

import Foundation

protocol DisplayLinkProtocol: AnyObject {
    func resume()
    func pause()
}

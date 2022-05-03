//
//  Definition.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/4/30.
//

import Foundation
#if os(macOS)
import AppKit
public typealias DRView = NSView
public typealias DRColor = NSColor
public typealias DRImage = NSImage
public typealias DRFont = NSFont
#else
import UIKit
public typealias DRView = UIView
public typealias DRColor = UIColor
public typealias DRImage = UIImage
public typealias DRFont = UIFont
#endif

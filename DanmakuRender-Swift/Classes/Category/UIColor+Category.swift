//
//  UIColor+Category.swift
//  DanmakuRender-Swift
//
//  Created by jimhuang on 2022/5/1.
//

import Foundation

extension DRColor {
    var brightness: CGFloat {
        #if os(macOS)
        let color: DRColor? = self.usingColorSpace(.deviceRGB)
        #else
        let color: DRColor? = self
        #endif
        var brightness: CGFloat = 0
        color?.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }
}


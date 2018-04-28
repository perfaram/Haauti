//
//  Rainbow.swift
//  ProgressKit
//
//  Created by Kauntey Suryawanshi on 09/07/15.
//  Copyright (c) 2015 Kauntey Suryawanshi. All rights reserved.
//

import Foundation
import Cocoa

@IBDesignable
open class Rainbow: MaterialProgress {

    override func configureLayers() {
        super.configureLayers()
        self.background = NSColor.clear
    }

    override open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        super.animationDidStop(anim, finished: flag)
        
        let colors = JodelAPISettings.colors.all
        
        progressLayer.strokeColor = colors.randomItem()!.cgColor
    }
}

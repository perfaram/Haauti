//
//  MaterialProgress.swift
//  ProgressKit
//
//  Created by Kauntey Suryawanshi on 30/06/15.
//  Copyright (c) 2015 Kauntey Suryawanshi. All rights reserved.
//

import Foundation
import Cocoa

private let duration = 1.5
typealias StrokeRange = (start: Double, end: Double)
private let strokeRange : StrokeRange = (start: 0.0, end: 0.8)

@IBDesignable
open class MaterialProgress: IndeterminateAnimation {

    @IBInspectable open var lineWidth: CGFloat = -1 {
        didSet {
            progressLayer.lineWidth = lineWidth
        }
    }

    override func notifyViewRedesigned() {
        super.notifyViewRedesigned()
        progressLayer.strokeColor = foreground.cgColor
    }

    var backgroundRotationLayer: CAShapeLayer = {
        var tempLayer = CAShapeLayer()
        return tempLayer
    }()

    var progressLayer: CAShapeLayer = {
        var tempLayer = CAShapeLayer()
        tempLayer.strokeEnd = CGFloat(strokeRange.end)
        tempLayer.lineCap = kCALineCapRound
        tempLayer.fillColor = NSColor.clear.cgColor
        return tempLayer
    }()

    //MARK: Animation Declaration
    var animationGroup: CAAnimationGroup = {
        var tempGroup = CAAnimationGroup()
        tempGroup.repeatCount = 1
        tempGroup.duration = duration
        return tempGroup
    }()
    
    var rotationAnimation: CABasicAnimation = {
        var tempRotation = CABasicAnimation(keyPath: "transform.rotation")
        tempRotation.repeatCount = Float.infinity
        tempRotation.fromValue = 0
        tempRotation.toValue = 1
        tempRotation.isCumulative = true
        tempRotation.duration = duration / 2
        return tempRotation
        }()
    
    private func makeAnimationforKeyPath(_ keyPath: String, range: StrokeRange) -> CABasicAnimation {
        let tempAnimation = CABasicAnimation(keyPath: keyPath)
        tempAnimation.repeatCount = 1
        tempAnimation.speed = 2.0
        tempAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        tempAnimation.fromValue = range.start
        tempAnimation.toValue =  range.end
        tempAnimation.duration = duration
        
        return tempAnimation
    }

    /// Makes animation for Stroke Start and Stroke End
    func makeStrokeAnimationGroup() {
        var strokeStartAnimation: CABasicAnimation!
        var strokeEndAnimation: CABasicAnimation!
        
        strokeEndAnimation = makeAnimationforKeyPath("strokeEnd", range: strokeRange)
        strokeStartAnimation = makeAnimationforKeyPath("strokeStart", range: strokeRange)
        strokeStartAnimation.beginTime = duration / 2
        animationGroup.animations = [strokeEndAnimation, strokeStartAnimation, ]
        animationGroup.delegate = self
    }

    override func configureLayers() {
        super.configureLayers()
        makeStrokeAnimationGroup()
        let rect = self.bounds

        backgroundRotationLayer.frame = rect
        self.layer?.addSublayer(backgroundRotationLayer)

        // Progress Layer
        let radius = (rect.width / 2) * 0.75
        progressLayer.frame =  rect
        progressLayer.lineWidth = lineWidth == -1 ? radius / 10 : lineWidth
        let arcPath = NSBezierPath()
        arcPath.appendArc(withCenter: rect.mid, radius: radius, startAngle: 0+90, endAngle: 360+90, clockwise: false)
        progressLayer.path = arcPath.CGPath
        backgroundRotationLayer.addSublayer(progressLayer)
    }

    var currentRotation = 0.0
    let π2 = Double.pi * 2

    override func startAnimation() {
        progressLayer.add(animationGroup, forKey: "strokeEnd")
        backgroundRotationLayer.add(rotationAnimation, forKey: rotationAnimation.keyPath)
        progressLayer.strokeEnd = CGFloat(strokeRange.end)
    }
    override func stopAnimation() {
        backgroundRotationLayer.removeAllAnimations()
        progressLayer.removeAllAnimations()
    }
    
    public var floatValue : Float = 0 {
        didSet {
            if animate { return }
            backgroundRotationLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(0)))
            currentRotation = 0
            progressLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat( currentRotation)))
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = CGFloat(floatValue)
            CATransaction.commit()
        }
    }
}

extension MaterialProgress: CAAnimationDelegate {
    open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if !animate { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        currentRotation += strokeRange.end * π2
        currentRotation = currentRotation.truncatingRemainder(dividingBy: π2)
        progressLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat( currentRotation)))
        CATransaction.commit()
        progressLayer.add(animationGroup, forKey: "strokeEnd")
    }
}

//
//  NSControl+Extensions.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 20/03/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//


import ObjectiveC
import Cocoa

final class Lifted<T> {
    let value: T
    init(_ x: T) {
        value = x
    }
}

private func lift<T>(x: T) -> Lifted<T>  {
    return Lifted(x)
}

func setAssociatedObject<T>(_ object: AnyObject, value: T, associativeKey: UnsafeRawPointer, policy: objc_AssociationPolicy) {
    if let v: AnyObject = value as? AnyObject {
        objc_setAssociatedObject(object, associativeKey, v,  policy)
    }
    else {
        objc_setAssociatedObject(object, associativeKey, lift(x: value),  policy)
    }
}

func getAssociatedObject<T>(_ object: AnyObject, associativeKey: UnsafeRawPointer) -> T? {
    if let v = objc_getAssociatedObject(object, associativeKey) as? T {
        return v
    }
    else if let v = objc_getAssociatedObject(object, associativeKey) as? Lifted<T> {
        return v.value
    }
    else {
        return nil
    }
}

extension NSControl {
    typealias ActionClosure = ((NSControl) -> Void)
    
    @objc
    private func callClosure(_ sender: NSControl) {
        onAction?(sender)
    }
    
    /**
     Closure version of `.action`
     ```
     let button = NSButton(title: "Unicorn", target: nil, action: nil)
     button.onAction = { sender in
     print("Button action: \(sender)")
     }
     ```
     */
    
    private struct AssociatedKey {
        static var onActionClosure = "onActionClosure"
    }
    
    var onAction: ActionClosure? {
        get {
            return getAssociatedObject(self, associativeKey: &AssociatedKey.onActionClosure)
        }
        
        set {
            if let value = newValue {
                setAssociatedObject(self, value: value, associativeKey: &AssociatedKey.onActionClosure, policy: objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                action = #selector(callClosure)
                target = self
            }
        }
    }
}

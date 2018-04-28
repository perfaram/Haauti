//
//  PageController.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 29/03/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

class PageController: NSPageController, NSPageControllerDelegate {
    
    var myViewArray = [/*"splash",*/ "details", "feed"]//, "two", "three"]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        PageController.sharedController = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        delegate = self
        self.arrangedObjects = myViewArray
        self.transitionStyle = .stackBook
        //self.presentViewController(<#T##viewController: NSViewController##NSViewController#>, animator: NSViewControllerPresentationAnimator())
    }
    
    static private var sharedController : PageController? = nil
    static public var shared : PageController {
        get {
            return sharedController!
        }
    }
    
    func pageController(_ pageController: NSPageController,
                        viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        
        switch identifier.rawValue {
        case "feed":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil)
                .instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "feed")) as! NSViewController
        case "details":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil)
                .instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "details")) as! NSViewController
        /*case "two":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil)
                .instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Page02")) as! NSViewController
        case "three":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil)
                .instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Page03")) as! NSViewController*/
        default:
            return self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: identifier.rawValue)) as! NSViewController
        }
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return NSPageController.ObjectIdentifier(rawValue: String(describing: object))
        
    }
    
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        self.completeTransition()
    }
    
}


//
//  ViewController.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 21/03/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

class MainViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded
            print(representedObject)
            self.view.window?.windowController?.document = representedObject as AnyObject
            let notif = Notification(name: Notification.Name("DocumentHasArrived"), object: representedObject, userInfo: nil)
            NotificationCenter.default.post(notif)
            
            //NSDocumentController.shared.addObserver(self, forKeyPath: "currentDocument", options: NSKeyValueObservingOptions.new, context: <#T##UnsafeMutableRawPointer?#>)
        }
    }

}


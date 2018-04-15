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
        }
    }

}


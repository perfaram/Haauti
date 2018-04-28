//
//  SourceView.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 25/02/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

class SourceView: NSOutlineView {
    
    override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
        let superFrame = super.frameOfCell(atColumn: column, row: row)
        
        if ((column == 0) /* && isGroupRow */) {
            return NSMakeRect(superFrame.origin.x - indentationPerLevel, superFrame.origin.y, self.bounds.size.width, superFrame.size.height)
        }
        
        return superFrame
    }
    
}


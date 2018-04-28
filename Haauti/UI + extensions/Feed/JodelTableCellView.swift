//
//  JodelTableCellView.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 23/02/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa
import Atributika
import LocalizedTimeAgo

class JodelTableRowView: NSTableRowView {
    override func drawSeparator(in dr: NSRect) {
        //do nothing, leaving the separator white
    }
}

class JodelTableCellView: NSTableCellView {
    weak var referencingJodel: AJodel! {
        didSet {
            matchReferencingJodel()
        }
    }
    
    weak var jodelAccount: JodelAccount!
    weak var parentFeedViewController: FeedViewController!
    
    func matchReferencingJodel() {
        self.deleteButton.isHidden = true
        
        self.color = referencingJodel.color
        self.layer?.backgroundColor = self.color.cgColor
        self.contrastColor = self.color.lighter()
        
        let tintedIcon = self.locationIcon.image?.imageWithTint(color: contrastColor)
        self.locationIcon.image = tintedIcon
        
        self.moreButton.image = NSImage.tripleDot
        
        self.content.stringValue = referencingJodel.message
        
        let fontSize = self.content.font?.pointSize
        let atstr = referencingJodel.message
            .styleHashtags(Style.font(.boldSystemFont(ofSize: fontSize!)))
            .styleMentions(Style.foregroundColor(.red))
            .attributedString
        
        self.content.attributedStringValue = atstr
        
        self.score.intValue = Int32(referencingJodel.score)
        self.timeDelta.stringValue =  "· " + self.referencingJodel.timeStamp.shortTimeAgo()
        
        if (self.referencingJodel.fromHome) {
            self.locationIcon.image = NSImage.homeIcon
            self.location.stringValue = "Hometown"
        } else {
            self.locationIcon.image = NSImage.mapMarkerIcon
            self.location.stringValue = {
                if (referencingJodel.distance <= 1) {
                    return "here"
                } else if (referencingJodel.distance <= 2) {
                    return "very close"
                } else if (referencingJodel.distance < 10) {
                    return "close"
                } else {
                    return "far (" + referencingJodel.location + ")"
                }
            }()
        }
        self.location.stringValue += " ·"
    }
    
    var color: NSColor! = { return NSColor.white }()
    
    @objc dynamic var contrastColor: NSColor! = { return NSColor.white }()
    @objc dynamic var textColor: NSColor! = { return NSColor.white }()
    
    @IBOutlet weak var locationIcon: NSImageView!
    @IBOutlet weak var location: NSTextField!
    @IBOutlet weak var timeDelta: NSTextField!
    
    @IBOutlet weak var score: NSTextField!
    
    @IBOutlet weak var content: NSTextField!
    
    @IBOutlet weak var upvoteButton: NSButton!
    @IBOutlet weak var downvoteButton: NSButton!
    @IBOutlet weak var moreButton: NSButton!
    
    @IBOutlet weak var deleteButton: NSButton!
}

class JodelCommentTableCellView: JodelTableCellView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        
    }
    
    @IBOutlet weak var crownIcon: NSImageView!
    @IBOutlet weak var userHandle: NSTextField!
    
}

class JodelFeedTableCellView: JodelTableCellView {
    
    @IBAction func buttonClicked(_ sender: NSButton!) {
        
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        self.wantsLayer = true
    }
    
    override func matchReferencingJodel() {
        super.matchReferencingJodel()
        
        let tintedIcon = self.commentIcon.image?.imageWithTint(color: contrastColor)
        self.commentIcon.image = tintedIcon
        
        self.commentCount.intValue = Int32(self.referencingJodel.childCount)
        
        if (referencingJodel.isSticky) {
            [score, timeDelta, upvoteButton, downvoteButton, moreButton, commentIcon, commentCount, channel].forEach { (control: NSView) in
                control.isHidden = true
            }
            deleteButton.isHidden = false
            deleteButton.onAction = { sender in
                self.jodelAccount.dismissSticky(self.referencingJodel).then({ (succeeded) in
                    self.parentFeedViewController.updateFeed()
                })
                let idxSet = IndexSet(integer: self.parentFeedViewController.tableView.row(for: self))
                self.parentFeedViewController.tableView.removeRows(at: idxSet, withAnimation: NSTableView.AnimationOptions.slideRight)
            }
        }
    }
    
    @IBOutlet weak var channel: NSTextField!
    
    @IBOutlet weak var commentIcon: NSImageView!
    @IBOutlet weak var commentCount: NSTextField!
}

class JodelDetailedTableCellView: JodelFeedTableCellView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    @IBOutlet weak var crownIcon: NSImageView!
    @IBOutlet weak var userHandle: NSTextField!
}

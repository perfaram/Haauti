//
//  SourceViewController.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 23/02/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

enum AccountSubType : String {
    case MyFeed
    case Pins
    case MyJodels
    case Replies
    case AccountDetails = "Account Details"
    
    static let allValues = [MyFeed, Pins, MyJodels, Replies, AccountDetails]
}

enum SourceViewItemSections : CustomStringConvertible {
    case Global
    case Account
    case Hashtag
    case Channel
    
    static let allValues = [Account, Hashtag, Channel]
    
    var description: String {
        get {
            switch self {
            case .Account:
                return "Account"
            case .Hashtag:
                return "Hashtags"
            case .Channel:
                return "Channels"
            case .Global:
                return "Jodel"
            }
        }
    }
}

enum SourceViewItemHierarchy {
    case Root
    case Header
    case Child
}

protocol SourceViewItem {
    var itemRole: SourceViewItemHierarchy { get }
    var itemSection: SourceViewItemSections { get }
    
    var children: [SourceViewItem] { get }
    
    var displayedIdentifier: String { get }
}

class SourceViewRootItem : SourceViewItem {
    let itemRole: SourceViewItemHierarchy = .Root
    let itemSection: SourceViewItemSections = .Global
    
    var displayedIdentifier: String {
        get {
            return self.itemSection.description //i18n
        }
    }
    
    let children: [SourceViewItem] = {
        return SourceViewItemSections.allValues.map { SourceViewHeaderItem(section: $0) }
    }()
}

class SourceViewChildItem : SourceViewItem {
    let itemRole: SourceViewItemHierarchy = .Child
    var itemSection: SourceViewItemSections
    
    var representedValue: String
    
    var displayedIdentifier: String {
        get {
            let prefix : String = {
                switch self.itemSection {
                case .Channel:
                    return "@"
                case .Hashtag:
                    return "#"
                default:
                    return ""
                }
            }()
            return prefix + self.representedValue
        }
    }
    
    var children: [SourceViewItem] = []
    
    init(section: SourceViewItemSections, value: String) {
        itemSection = section
        representedValue = value
    }
}

class SourceViewAccountChildItem : SourceViewItem {
    let itemRole: SourceViewItemHierarchy = .Child
    let itemSection: SourceViewItemSections = .Account
    var subType: AccountSubType
    
    var displayedIdentifier: String {
        get {
            return self.subType.rawValue //i18n
        }
    }
    
    var children: [SourceViewItem] = []
    
    init(subtype: AccountSubType) {
        subType = subtype
    }
}

class SourceViewHeaderItem : SourceViewItem {
    let itemRole: SourceViewItemHierarchy = .Header
    var itemSection: SourceViewItemSections
    
    lazy var children: [SourceViewItem] = {
        switch itemSection {
        case .Account:
            return AccountSubType.allValues.map { SourceViewAccountChildItem(subtype: $0) }
        case .Hashtag:
            return []
        case .Channel:
            return []
        case .Global:
            return []
        }
    }()
    
    var displayedIdentifier: String {
        get {
            return self.itemSection.description //i18n
        }
    }
    
    init(section: SourceViewItemSections) {
        itemSection = section
    }
}

class SourceViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    @IBOutlet weak var sourceView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        sourceView.expandItem(nil, expandChildren: true)
        //sourceView.indentationMarkerFollowsCell = false
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item {
            if let item = item as? SourceViewItem {
                return item.children.count
            } else {
                preconditionFailure()
            }
        }
        return SourceViewRootItem().children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item {
            if let item = item as? SourceViewItem {
                return item.children[index]
            } else {
                preconditionFailure()
            }
        }
        return SourceViewRootItem().children[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        precondition(item is SourceViewItem)
        let item = item as! SourceViewItem
        
        if item.itemRole == .Header {
            return false
        }
        return true
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let item = sourceView.item(atRow: sourceView.selectedRow)
        if let item = item {
            if let item = item as? SourceViewItem {
                if item.itemRole != .Child {
                    preconditionFailure()
                }
                if item.itemSection == .Account {
                    guard let item = item as? SourceViewAccountChildItem else { preconditionFailure() }
                    if item.subType == .AccountDetails {
                        PageController.shared.navigateForward(to: "details")
                    } else {
                        PageController.shared.navigateForward(to: "feed")
                    }
                    //prepare new feed view and push it
                    
                    
                }
            } else {
                preconditionFailure()
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        precondition(item is SourceViewItem)
        let item = item as! SourceViewItem
        
        var identifier : NSUserInterfaceItemIdentifier
        var stringValue : String
        
        switch item.itemRole {
        case .Header:
            identifier = NSUserInterfaceItemIdentifier("HeaderCell")
            stringValue = item.displayedIdentifier.uppercased()
        default:
            identifier = NSUserInterfaceItemIdentifier("DataCell")
            stringValue = item.displayedIdentifier
        }
        
        let cellview = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
        
        cellview.textField?.stringValue = stringValue
        
        return cellview
    }
    
    /*-(NSView *)outlineView:(NSOutlineView *)ov viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
     {   NSTableCellView *result = nil;
     result = [ov makeViewWithIdentifier:@"HeaderCell" owner:self];
     [[result textField]setStringValue:@"myString"];
     return result;
     }*/
    
}


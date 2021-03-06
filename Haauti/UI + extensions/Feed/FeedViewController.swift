//
//  FeedViewController.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 23/02/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//  Portions credits to Debasis Das on 5/15/17.
//  Portions Copyright © 2017 Knowstack.
//

import Cocoa
import PullRefreshableScrollView

class FeedRefreshAccessoryView : NSView, AccessoryViewForPullRefreshable {
    @IBOutlet var rainbow1 : Rainbow!
    @IBOutlet var rainbow2 : Rainbow!
    @IBOutlet var rainbow3 : Rainbow!
    lazy var indicatorCollection: [Rainbow] = [rainbow1, rainbow2, rainbow3]
    
    func viewDidStick(_ sender: Any?) {
        indicatorCollection.forEach { $0.animate = true }
    }
    
    func viewDidRecede(_ sender: Any?) {
        indicatorCollection.forEach { $0.animate = false }
    }
    
    func viewDidReachElasticityPercentage(_ sender: Any?, percentage: Double) {
        indicatorCollection.forEach { $0.floatValue = Float(percentage / 100) }
    }
    
    override func viewDidMoveToWindow() {
        self.isHidden = false
        indicatorCollection.forEach { $0.isHidden = false }
        self.wantsLayer = true
    }
}

class FeedViewController: NSViewController {
    var jodelAccount: JodelAccount?
    //provide empty state for tableview ; pull to refresh
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var refreshView: FeedRefreshAccessoryView!
    @IBOutlet var p2rScrollView: PullRefreshableScrollView!
    
    var jodelsInFeed = [AJodel]()
    var jodelFeedType = JodelFeedType.recent(mine: false, hashtag: nil, channel: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.translatesAutoresizingMaskIntoConstraints = false;
        self.tableView.usesAutomaticRowHeights = true
        
        self.tableView.intercellSpacing = NSMakeSize(0, 3)
        self.tableView.enclosingScrollView?.needsLayout = true
        
        let prv = (self.tableView.superview?.superview as? PullRefreshableScrollView)
        //prv?.viewDidMoveToWindow()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.docHasArrived), name: Notification.Name("DocumentHasArrived"), object: nil)
    }
    
    @objc func docHasArrived(notif: NSNotification) {
        self.jodelAccount = notif.object as! JodelAccount
        jodelAccount!.register(feedDelegate: self, forFeed: jodelFeedType)
        jodelAccount!.updateJodelList(for: jodelFeedType)
    }
}

extension FeedViewController : PullRefreshableScrollViewDelegate {
    func prScrollView(_ sender: PullRefreshableScrollView, triggeredOnEdge: PullRefreshableScrollView.ViewEdge) -> Bool {
        //check internet => ev ret false
        jodelAccount?.updateJodelList(for: jodelFeedType)
        return true
    }
    
    var topAccessoryView : (NSView & AccessoryViewForPullRefreshable)? {
        get {
            return refreshView
        }
    }
}

extension FeedViewController : JodelFeedDelegate {
    func feedUpdated(_ jodels: [AJodel]) {
        jodelsInFeed = jodels
        p2rScrollView.endActions()
        self.tableView.reloadData()
    }
    
    func updateFeed() {
        jodelAccount?.updateJodelList(for: jodelFeedType)
    }
    
    func errorOccurred(_: JodelError) {
        //don't reinvent the wheel - swift error presenter ? / framework w/ presenter ?
    }
}

extension FeedViewController : NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return jodelsInFeed.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let result:JodelFeedTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "jodelFeedRow"), owner: self) as! JodelFeedTableCellView
        
        result.referencingJodel = jodelsInFeed[row]
        result.jodelAccount = jodelAccount
        result.parentFeedViewController = self
        return result
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return JodelTableRowView()
    }
    
}

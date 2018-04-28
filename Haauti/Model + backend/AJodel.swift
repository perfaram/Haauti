//
//  AJodel.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 23/02/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa
import CoreLocation
import Promise
import SwiftyJSON

class AJodel {
    var jsonBag: String!
    var postId: String!
    
    var fromHome: Bool = false
    var distance: Int = 0
    var location: String = "[NOWHERE]"
    
    var score: Int = 0
    var gotThanks: Bool = false
    var childCount: Int = 0
    var ojReplied: Bool = false
    var pinCount: Int = 0
    var shareCount: Int = 0
    
    var message: String = "[NO MESSAGE]"
    var timeStamp: Date = Date()
    var color: NSColor = NSColor.black
    
    var userHandle: String = "oj"
    
    var parentChannel: String = "@main"
    
    var children: [AJodel]?
    
    var isSticky: Bool = false
    var buttons: [String]?
    
    convenience init(fromJson json: String) {
        self.init()
        
        self.jsonBag = json
        //parse json
    }
}

enum JodelFeedType {
    case recent(mine: Bool, hashtag: String?, channel: String?)
    case popular(mine: Bool, hashtag: String?, channel: String?)
    case discussed(mine: Bool, hashtag: String?, channel: String?)
    
    //case mainFeed()
    
    case pinned
    case replied
    case voted
    
    case stickies
    //case search(term: String)
}

extension JodelFeedType: RawRepresentable {
    typealias RawValue = String
    
    static func parsePotentiallyAmbiguousString(_ string: String) -> [String] {
        guard let startingDashIndex = string.index(of: "-") else { return [String]() }
        let firstIndexOfLengthString = string.index(after: startingDashIndex)
        guard let terminatingDashIndex = string[firstIndexOfLengthString...].index(of: "-") else { return [String]() }
        
        let startOfPortionIndex = string.index(after: terminatingDashIndex)
        
        let portionLengthString = string[firstIndexOfLengthString..<terminatingDashIndex]
        guard let portionLength = Int(portionLengthString) else { return [String]() }
        let endOfPortionIndex = string.index(startOfPortionIndex, offsetBy: portionLength)
        
        let portion = string[startOfPortionIndex..<endOfPortionIndex]
        
        let potentialNextString = String(string[endOfPortionIndex...])
        if let startingDashIndex = potentialNextString.index(of: "-") {
            var endOfStringParsed = parsePotentiallyAmbiguousString(potentialNextString)
            endOfStringParsed.append(String(portion))
            return endOfStringParsed.reversed()
        }
        
        return [String(portion)]
    }
    
    init?(rawValue: RawValue) {
        guard rawValue.count >= 1 else { return nil }
        
        if rawValue[0].isUpper() {
            guard rawValue.count >= 2 else { return nil }
            
            let isMine = rawValue[1] == "m"
            var hashtag : String? = nil
            var channel : String? = nil
            if rawValue.count > 2 {
                let parsed = JodelFeedType.parsePotentiallyAmbiguousString(rawValue)
                if parsed.count >= 1 {
                    hashtag = parsed[0]
                    channel = parsed[1]
                }
                else {
                    return nil
                }
            }
            
            switch rawValue[0] {
            case "R": self = .recent(mine: isMine, hashtag: hashtag, channel: channel)
            case "P": self = .popular(mine: isMine, hashtag: hashtag, channel: channel)
            case "D": self = .discussed(mine: isMine, hashtag: hashtag, channel: channel)
            default: return nil
            }
        }
        else {
            switch rawValue {
            case "r": self = .replied
            case "p": self = .pinned
            case "v": self = .voted
            case "s": self = .stickies
            default: return nil
            }
        }
    }
    
    private func buildStringRepresentingWrappedValue(fromString: String, mine: Bool, hashtag: String?, channel: String?) -> String {
        var string = fromString
        string += (mine ? "m" : "_")
        
        if let hashtag = hashtag {
            string += "-" + String(hashtag.count) + "-" + hashtag
        }
        
        if let channel = channel {
            string += "-" + String(channel.count) + "-" + channel
        }
        
        return string
    }
    
    var rawValue: RawValue {
        switch self {
        case .replied: return "r"
        case .pinned: return "p"
        case .voted: return "v"
        case .stickies: return "s"
        case .recent(let mine, let hashtag, let channel):
            let str = "R"
            return buildStringRepresentingWrappedValue(fromString: str, mine: mine, hashtag: hashtag, channel: channel)
        case .popular(let mine, let hashtag, let channel):
            let str = "P"
            return buildStringRepresentingWrappedValue(fromString: str, mine: mine, hashtag: hashtag, channel: channel)
        case .discussed(let mine, let hashtag, let channel):
            let str = "D"
            return buildStringRepresentingWrappedValue(fromString: str, mine: mine, hashtag: hashtag, channel: channel)
        }
    }
}

extension JodelFeedType: Hashable {
    var hashValue: Int {
        get {
            return self.rawValue.hashValue
        }
    }
    
    static func ==(lhs: JodelFeedType, rhs: JodelFeedType) -> Bool {
        return (lhs.rawValue.hashValue == rhs.rawValue.hashValue)
    }
}

protocol JodelFeedDelegate {
    func feedUpdated(_: [AJodel])
    func updateFeed()
    func errorOccurred(_: JodelError)
}

protocol JodelAccountDelegate {
    func update(karma: Int)
    func errorOccurred(_: JodelError)
}

class AFeed {
    public private(set) var feedType: JodelFeedType
    
    init(_ type: JodelFeedType) {
        feedType = type
    }
}


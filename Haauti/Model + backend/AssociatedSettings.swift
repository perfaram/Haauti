//
//  AssociatedSettings.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 28/04/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa
import CoreLocation

struct AssociatedSettings {
    var followUserLocation: Bool = true
    
    func toCocoaDict() -> NSDictionary {
        let dict = NSMutableDictionary.init()
        dict["follow"] = followUserLocation
        return dict
    }
    
    static func fromCocoaDict(_ dict: NSDictionary) -> AssociatedSettings? {
        guard let dict = dict as? Dictionary<String, Any> else { return nil }
        
        var followUserLocation = false
        if let follow = dict["follow"] as? Bool {
            followUserLocation = follow
        }
        
        return AssociatedSettings(followUserLocation: followUserLocation)
    }
}

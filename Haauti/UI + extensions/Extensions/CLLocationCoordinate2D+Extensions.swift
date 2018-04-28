//
//  CLLocationCoordinate2D+Extensions.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 28/04/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import CoreLocation
import Foundation

extension CLLocationCoordinate2D : Equatable {
    static public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        let latCompared = (lhs.latitude == rhs.latitude)
        let lngCompared = (lhs.longitude == rhs.longitude)
        return (lngCompared && latCompared)
    }
    
    static public func !=(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return !(rhs == lhs)
    }
}



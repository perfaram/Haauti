//
//  JodelAccount.swift
//  fronzel
//
//  Created by Perceval FARAMAZ on 17/03/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa
import CoreLocation
import Promise
import SwiftyJSON

public enum JodelError : Error, CustomStringConvertible {
    public enum InternalErrorTypes {
        case UnparseableEndpointURL
        case UnexpectedEmptyAuthenticationBag
        case UnexpectedResponseType
        case ParsingError
        case NotImplemented
        case UnGeocodableCity
    }
    
    public enum APIErrorTypes {
        case MalformedResponse
        case UnexpectedStatusCode(code: Int)
        case Double401
    }
    
    case APIError(APIErrorTypes)
    case InternalError(InternalErrorTypes)
    
    public var description: String {
        return ""
    }
}

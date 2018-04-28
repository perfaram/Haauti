//
//  SwiftConvenience.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 28/04/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Foundation

public func Init<Type>(_ value : Type, _ block: (_ object: Type) -> Void) -> Type
{
    block(value)
    return value
}

//
//  CollisionCategory.swift
//  DTARKitExample1
//
//  Created by Dima Tsurkan on 8/25/17.
//  Copyright © 2017 Dima Tsurkan. All rights reserved.
//

import Foundation

struct CollisionCategory: OptionSet {
    let rawValue: Int
    
    static let arBullets  = CollisionCategory(rawValue: 1 << 0)
    static let logos = CollisionCategory(rawValue: 1 << 1)
}

//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Eugen on 25/10/14.
//  Copyright (c) 2014 olgen. All rights reserved.
//

import Foundation
import CoreData

@objc (FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData

}

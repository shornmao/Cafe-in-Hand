//
//  ManagedOrder+CoreDataProperties.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/27.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import Foundation
import CoreData


extension ManagedOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedOrder> {
        return NSFetchRequest<ManagedOrder>(entityName: "Order");
    }

    @NSManaged public var dayid: Int64
    @NSManaged public var guest: String?
    @NSManaged public var id: NSDate?
    @NSManaged public var total: NSDecimalNumber?
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension ManagedOrder {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: ManagedOrderItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: ManagedOrderItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

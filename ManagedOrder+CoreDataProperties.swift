//
//  ManagedOrder+CoreDataProperties.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/20.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import Foundation
import CoreData


extension ManagedOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedOrder> {
        return NSFetchRequest<ManagedOrder>(entityName: "Order");
    }

    @NSManaged public var guest: String?
    @NSManaged public var id: NSDate?
    public var date_id: String? {
        get {
            if let calendar = NSCalendar(identifier: .ISO8601), let date = id as? Date {
                let year = Int64(calendar.component(.year, from: date))
                let month = Int64(calendar.component(.month, from: date))
                return "\(year * 100 + month)"
            } else {
                return nil
            }
        }
    }
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension ManagedOrder {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: NSManagedObject)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: NSManagedObject)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

//
//  ManagedOrder+CoreDataProperties.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/24.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import Foundation
import CoreData


extension ManagedOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedOrder> {
        return NSFetchRequest<ManagedOrder>(entityName: "Order");
    }

    public var dateid: String? {
        get {
            if let calendar = NSCalendar(identifier: .ISO8601) {
                let year = calendar.component(.year, from: id as! Date)
                let month = calendar.component(.month, from: id as! Date)
                let day = calendar.component(.day, from: id as! Date)
                return "\(year * 10000 + month * 100 + day)"
            } else {
                return nil
            }
        }
    }
    @NSManaged public var guest: String?
    @NSManaged public var id: NSDate?
    public var monthid: String? {
        get {
            if let calendar = NSCalendar(identifier: .ISO8601) {
                let year = calendar.component(.year, from: id as! Date)
                let month = calendar.component(.month, from: id as! Date)
                return "\(year * 100 + month)"
            } else {
                return nil
            }
        }
    }
    public var total: NSDecimalNumber? {
        get {
            let sum = NSDecimalNumber(value: 0)
            guard let _ = items else {
                return nil
            }
            for item in items! {
                if let orderItem = item as? ManagedOrderItem, let subtotal = orderItem.subtotal {
                    sum.adding(subtotal)
                } else {
                    return nil
                }
            }
            return sum
        }
    }
    public var yearid: String? {
        get {
            if let calendar = NSCalendar(identifier: .ISO8601) {
                let year = calendar.component(.year, from: id as! Date)
                return "\(year)"
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
    @NSManaged public func addToItems(_ value: ManagedOrderItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: ManagedOrderItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

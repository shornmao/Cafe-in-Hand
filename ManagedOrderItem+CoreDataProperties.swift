//
//  ManagedOrderItem+CoreDataProperties.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/24.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import Foundation
import CoreData


extension ManagedOrderItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedOrderItem> {
        return NSFetchRequest<ManagedOrderItem>(entityName: "OrderItem");
    }

    @NSManaged public var amount: Int16
    @NSManaged public var name: String?
    @NSManaged public var price: NSDecimalNumber?
    public var subtotal: NSDecimalNumber? {
        get {
            return price?.multiplying(by: NSDecimalNumber(value: amount))
        }
    }
    @NSManaged public var order: ManagedOrder?
    @NSManaged public var menuitem: NSManagedObject?

}

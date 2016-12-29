//
//  MonthlyReportViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/26.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class OrdersViewController: UITableViewController {
    
    var sectionNameMonths:[String] = []
    var orderInfoList:[[(day:Int, count:Int, sum:Double)]] = [[]]
    var revenueMonthly:[Double] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.hasNewOrderPending {
            // fetch request data from persistent store, have to store pending insertion at first
            appDelegate.saveContext()
        }
        // always fetch while loading
        fetch()
        appDelegate.hasNewOrderPending = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.hasNewOrderPending {
            // fetch request data from persistent store, have to store pending insertion at first
            appDelegate.saveContext()
            fetch()
            appDelegate.hasNewOrderPending = false
        }
    }
    
    // MARK: - Tools

    func fetch() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext

        // option1: select dayid,count(dayid),sum(total) order by id group by dayid from Order
        //          Note: dayid and total have to be not transient
        // option2: select order.dayid, count(order.dayid), sum(subtotal) order by order.id group by order.dayid from OrderItem join Order
        //          Note: Maybe more time for sum calculation
        
        // Implementation for option 1
        let keyPathForCountExpression = NSExpression(forKeyPath: "dayid")
        let countExpression = NSExpression(forFunction: "count:", arguments: [keyPathForCountExpression])
        let count = NSExpressionDescription()
        count.name = "count"
        count.expressionResultType = .integer64AttributeType
        count.expression = countExpression

        let keyPathForSumExpression = NSExpression(forKeyPath: "total")
        let sumExpression = NSExpression(forFunction: "sum:", arguments: [keyPathForSumExpression])
        let sum = NSExpressionDescription()
        sum.name = "sum"
        sum.expressionResultType = .decimalAttributeType
        sum.expression = sumExpression
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Order")
        request.predicate = NSPredicate(value: true)
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        request.resultType = .dictionaryResultType
        request.propertiesToGroupBy = ["dayid"]
        request.propertiesToFetch = ["dayid", count, sum]

        do {
            let objList = try context.fetch(request)
            guard !objList.isEmpty else {
                return
            }
            sectionNameMonths.removeAll()
            orderInfoList.removeAll()
            var currentMonth: Int?
            var section = -1
            for obj in objList {
                if let dict = obj as? NSDictionary {
                    if let day = dict.value(forKey: "dayid") as? Int, let count = dict.value(forKey: "count") as? NSNumber, let sum = dict.value(forKey: "sum") as? NSDecimalNumber {
                        let month = day / 100
                        if month != currentMonth {
                            // month is changed
                            sectionNameMonths.append(monthName(monthid: month))
                            currentMonth = month
                            orderInfoList.append([(day, count.intValue, sum.doubleValue)])
                            revenueMonthly.append(sum.doubleValue)
                            section += 1
                        } else {
                            orderInfoList[section].append((day, count.intValue, sum.doubleValue))
                            revenueMonthly[section] += sum.doubleValue
                        }
                    }
                }
            }
        } catch {
            fatalError("Failed to fetch Person")
        }
        
        tableView.reloadData()
    }
    
    func monthName(monthid: Int) -> String {
        let dateComponents = DateComponents(calendar: Calendar(identifier: .iso8601), year: monthid / 100, month: monthid % 100)
        if let date = NSCalendar.current.date(from: dateComponents) {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = NSCalendar.current
            dateFormatter.locale = NSLocale.current
            dateFormatter.setLocalizedDateFormatFromTemplate("YYYY MMMM")
            return dateFormatter.string(from: date)
        }
        return "\(monthid)"
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionNameMonths.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderInfoList[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(sectionNameMonths[section]) Revenue: \(NSLocale.current.currencySymbol!)\(revenueMonthly[section])"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Daily Orders Cell", for: indexPath)

        // Configure the cell...
        let orderInfo = orderInfoList[indexPath.section][indexPath.row]
        let dayid = orderInfo.day
        let dateComponents = DateComponents(calendar: Calendar(identifier: .iso8601), year: dayid / 10000, month: dayid / 100 % 100, day: dayid % 100)
        if let date = NSCalendar.current.date(from: dateComponents) {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = NSCalendar.current
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateStyle = .long
            cell.textLabel?.text = dateFormatter.string(from: date)
            cell.detailTextLabel?.text = "\(NSLocale.current.currencySymbol!)\(orderInfo.sum) from \(orderInfo.count) order(s)"
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let dailyReportViewController = segue.destination as? DailyReportViewController, let cell = sender as? UITableViewCell {
            if let indexPath = tableView.indexPath(for: cell) {
                dailyReportViewController.dayid = orderInfoList[indexPath.section][indexPath.row].day
            }
        }
    }

}

//
//  DailyReportViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/27.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class DailyReportViewController: UITableViewController {
    
    var dayid: Int?
    var infoOrders: [(id:Date, date:String , guest:String, total:Double)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if let day = dayid {
            let dateComponents = DateComponents(calendar: Calendar(identifier: .iso8601), year: day / 10000, month: day / 100 % 100, day: day % 100)
            if let date = NSCalendar.current.date(from: dateComponents) {
                let dateFormatter = DateFormatter()
                dateFormatter.calendar = NSCalendar.current
                dateFormatter.locale = NSLocale.current
                dateFormatter.dateStyle = .long
                navigationItem.title = dateFormatter.string(from: date)
            }
        }
        
        fetch()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.pendingDayOfOrders.removeAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let day = dayid {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if appDelegate.pendingDayOfOrders.contains(day) {
                appDelegate.saveContext()
                fetch()
                appDelegate.pendingDayOfOrders.removeAll()
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Tools
    
    func fetch() {
        // select id, guest, total order by id where dayid = <#dayid> from Order
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let day = dayid, let context = appDelegate?.persistentContainer.viewContext {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Order")
            request.predicate = NSPredicate(format: "dayid = %@", "\(day)")
            request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
            request.propertiesToFetch = ["id", "guest", "total"]
            request.resultType = .dictionaryResultType
            do {
                let objs = try context.fetch(request)
                infoOrders.removeAll()
                for obj in objs {
                    if let dict = obj as? NSDictionary {
                        if let date = dict["id"] as? Date, let guest = dict["guest"] as? String, let total = dict["total"] as? Double {
                            infoOrders.append((date, DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium), guest, total))
                        }
                    }
                }
            } catch {
                fatalError("Failed to fetch <Order> for \(day)")
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // calculate sections count from fetched result controller
        return infoOrders.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order Item Cell", for: indexPath)

        // Configure the cell with info from infoOrders
        let currency = NSLocale.current.currencySymbol
        let orderInfo = infoOrders[indexPath.row]
        cell.textLabel?.text = orderInfo.date
        cell.detailTextLabel?.text = "\(orderInfo.guest) for \(currency!)\(orderInfo.total)"

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
        if let orderInfoViewController = segue.destination as? OrderInfoViewController, let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            let orderInfo = infoOrders[indexPath.row]
            orderInfoViewController.id = orderInfo.id
            orderInfoViewController.guest = orderInfo.guest
            orderInfoViewController.total = orderInfo.total
        }
    }

}

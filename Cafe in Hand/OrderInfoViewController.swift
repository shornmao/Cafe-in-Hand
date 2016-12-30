//
//  OrderInfoViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/12/29.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class OrderInfoViewController: UIViewController, UITableViewDataSource {
    
    var id:Date?
    var guest:String = ""
    var total = 0.0
    var orderList:[ManagedOrderItem] = []

    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var guestLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        
        if let date = id {
            idLabel.text = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)
            guestLabel.text = guest
            totalLabel.text = "\(NSLocale.current.currencySymbol!)\(total)"
            
            // select all from OrderItem join Order where order.id = <#date>
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "OrderItem")
            request.predicate = NSPredicate(format: "order.id = %@", date as CVarArg)
            do {
                orderList = try context.fetch(request) as! [ManagedOrderItem]
            } catch {
                fatalError("Failed to fetch <OrderItem>")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order Item Cell", for: indexPath)
        
        if let orderInfoCell = cell as? OrderItemInfoCell {
            let orderItem = orderList[indexPath.row]
            if let name = orderItem.name {
                orderInfoCell.nameLabel.text = name
            }
            orderInfoCell.amountLabel.text = "\(orderItem.amount)"
            if let price = orderItem.price?.doubleValue {
                orderInfoCell.priceLabel.text = "\(NSLocale.current.currencySymbol!)\(price)"
            }
            if let subtotal = orderItem.subtotal?.doubleValue {
                orderInfoCell.subtotalLabel.text = "\(NSLocale.current.currencySymbol!)\(subtotal)"
            }
        }
        
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

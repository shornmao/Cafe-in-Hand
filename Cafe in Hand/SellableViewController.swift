//
//  SellableViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/11/30.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class SellableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, SellableItemCellDelegate, CashPaymentControllerDelegate {
    
    var amountList : [IndexPath : Int] = [:]
    var fetchController : NSFetchedResultsController<NSFetchRequestResult>?
    var orderDate : Date?
    let defaultGuestName = NSLocalizedString("No Name", comment: "Default guest name")
    let defaultTotal = 0.0

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var payButton: UIButton!
    
    @IBAction func doneEditing(_ sender: AnyObject) {
        if let textField = sender as? UITextField {
            textField.resignFirstResponder()
        }
    }

    @IBAction func emptyTapped(_ sender: AnyObject) {
        presentAlertConfirmation(NSLocalizedString("Amount for all item will be reset to zero.", comment: "Empty shopping cart warning message"), sender: sender as! UIButton, confirmedAction: emptyCart, by: self)
    }

    @IBAction func discardTapped(_ sender: AnyObject) {
        presentAlertConfirmation(NSLocalizedString("Current order will be discarded and a new order will be created.", comment: "Discard and new order warning message"), sender: sender as! UIButton, confirmedAction: newOrder, by: self)
    }

    @IBAction func payTapped(_ sender: AnyObject) {
        // check amount list, if no element, it dosen't make sense
        guard !amountList.isEmpty else {
            presentAlertInvalidation(NSLocalizedString("The order make no sense if no item is selected.", comment: "Error message for empty order"), by: self)
            return
        }
        
        presentAlertConfirmation(NSLocalizedString("Current order will be payed and closed, and also a new order will be created.", comment: "Pay order warning message"), sender: sender as! UIButton, confirmedAction: payOrder, by: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(SellableViewController.saveTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false

        // use fetched results controller
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MenuItem")
        request.predicate = NSPredicate(format: "%K == YES", "on_stock")
        request.sortDescriptors = [NSSortDescriptor(key: "category.name", ascending: true)]
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let context = appDelegate?.persistentContainer.viewContext {
            
            fetchController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "category.name", cacheName: nil)
            fetchController?.delegate = self
            do {
                try fetchController?.performFetch()
            } catch {
                fatalError("Failed to fetch on first time")
            }
        }
        
        // create new order
        newOrder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let context = fetchController?.managedObjectContext {
            navigationItem.rightBarButtonItem?.isEnabled = context.hasChanges
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Tools
    
    func saveTapped() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.saveContext()
        }
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func newOrder(_ : UIAlertAction? = nil) {
        orderDate = Date()
        idLabel.text = DateFormatter.localizedString(from: orderDate!, dateStyle: .medium, timeStyle: .medium)
        nameLabel.text = defaultGuestName
        emptyCart()
    }
    
    func emptyCart(_ : UIAlertAction? = nil) {
        totalLabel.text = "\(defaultTotal)"
        amountList.removeAll()
        for cell in tableView.visibleCells {
            (cell as! SellableItemCell).amount = 0
        }
    }
    
    func payOrder(_: UIAlertAction? = nil) {
        // pay for order with cash only
        let total = Double(totalLabel.text!)!
        let cashPaymentController = CashPaymentController(nibName: "CashPaymentController", bundle: nil)
        cashPaymentController.payment = total
        cashPaymentController.modalPresentationStyle = .popover
        cashPaymentController.dismissionDelegate = self
        present(cashPaymentController, animated: true, completion: nil)
        if let presentationController = cashPaymentController.popoverPresentationController {
            presentationController.permittedArrowDirections = [.left, .right]
            presentationController.sourceView = payButton
            presentationController.sourceRect = payButton.frame
        }
    }
    
    func generateOrder() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let guest = nameLabel.text
        if let order = NSEntityDescription.insertNewObject(forEntityName: "Order", into: context) as? ManagedOrder {
            order.id = NSDate(timeInterval: 0, since: orderDate!)
            let calendar = Calendar(identifier: .iso8601)
            let year = calendar.component(.year, from: orderDate!)
            let month = calendar.component(.month, from: orderDate!)
            let day = calendar.component(.day, from: orderDate!)
            let dayid = year * 10000 + month * 100 + day
            order.dayid = Int64(dayid)
            order.guest = guest
            order.total = NSDecimalNumber(string: totalLabel.text)
            for (indexPath, amount) in amountList {
                if let orderItem = NSEntityDescription.insertNewObject(forEntityName: "OrderItem", into: context) as? ManagedOrderItem {
                    orderItem.amount = Int16(amount)
                    if let menuItemObj = fetchController?.object(at: indexPath) as? NSManagedObject {
                        orderItem.price = menuItemObj.value(forKey: "price") as? NSDecimalNumber
                        orderItem.name = menuItemObj.value(forKey: "name") as? String
                    } else {
                        fatalError("Failed to located menu_item object")
                    }
                    order.addToItems(orderItem)
                } else {
                    fatalError("Failed to insert new order item")
                }
            }
            navigationItem.rightBarButtonItem?.isEnabled = true
            appDelegate.hasNewOrderPending = true
            appDelegate.pendingDayOfOrders.insert(dayid)
            
            // create new order
            newOrder()
        } else {
            fatalError("Failed to open 'Order'")
        }
        
    }
        
    func calculateTotal() {
        var total = 0.0
        for (indexPath, amount) in amountList {
            if amount > 0 {
                // calculate total
                if let obj = fetchController?.object(at: indexPath) as? NSManagedObject {
                    let price = obj.value(forKey: "price") as! Double
                    total += (price * Double(amount))
                }
            }
        }
        totalLabel.text = "\(total)"
    }
    
    // MARK: - Sellable item cell delegate
    
    func totalChanged(sender: SellableItemCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            let amount = sender.amount
            if amount != 0 {
                amountList[indexPath] = amount
            } else {
                amountList.removeValue(forKey: indexPath)
            }
        }
        calculateTotal()
    }
    
    // MARK: - Cash payment controller delegate
    
    func dismissed(_ controller: CashPaymentController, cancel: Bool) {
        if cancel {
            controller.dismiss(animated: true, completion: nil)
        } else {
            controller.dismiss(animated: true, completion: {
                self.generateOrder()
                presentAlertInformation(NSLocalizedString("Order is payed", comment: "Information Message for Order Payment"), by: self)
            })
        }
    }
    
    // MARK: - Feched results controller delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections([sectionIndex], with: .automatic)
        case .delete:
            tableView.deleteSections([sectionIndex], with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            if newIndexPath == nil {
                tableView.reloadRows(at: [indexPath!], with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath!], with: .automatic)
                tableView.insertRows(at: [newIndexPath!], with: .automatic)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        // default is uneccessary, because all valid type is enumarated.
//        default:
//            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // calculate sections count from fetched result controller
        return (fetchController?.sections?.count)!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // calculate rows count of one section from fetched result controller
        guard fetchController?.sections?.isEmpty == false else {
            return 0
        }
        if let sectionInfo = fetchController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Sellable Item Cell", for: indexPath) as! SellableItemCell
        
        // Configure the cell with amount from amount list
        if let amount = amountList[indexPath] {
            cell.amount = amount
        } else {
            cell.amount = 0
        }

        // Configure the cell with info from fetched result controller
        cell.delegate = self
        if let obj = fetchController?.object(at: indexPath) as? NSManagedObject, let name = obj.value(forKey: "name") as? String, let price = obj.value(forKey: "price") as? Double {
            let icon = obj.value(forKey: "icon") as? Data
            cell.configure(name: name, image: icon, price: price)
        } else {
            fatalError("Failed to display item info")
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard fetchController?.sections?.isEmpty == false else {
            return nil
        }
        if let sectionInfo = fetchController?.sections?[section] {
            return sectionInfo.name
        }
        return nil
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // delete actually to perform move item from sellable to unsellable
            // get object from fetched results controller
            if let obj = fetchController?.object(at: indexPath) as? NSManagedObject {
                // delete object from context
                obj.setValue(false, forKey: "on_stock")
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let itemInfoViewController = segue.destination as? ItemInfoViewController {
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell), let obj = fetchController?.object(at: indexPath) {
                itemInfoViewController.objectMenuItem = obj as? NSManagedObject
                itemInfoViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Unsell", comment: "Unsell Button Title"), style: .done, target: itemInfoViewController, action: #selector(ItemInfoViewController.unsell))
            }
        }
    }

}

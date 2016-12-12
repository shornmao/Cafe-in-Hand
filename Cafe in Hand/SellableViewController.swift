//
//  SellableViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/11/30.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class SellableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, OrderItemCellDelegate {
    
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
        presentAlertConfirmation(NSLocalizedString("Amount for all item will be reset to zero.", comment: "Empty shopping cart warning message"), sender: sender as! UIButton, confirmedAction: emptyCart)
    }

    @IBAction func discardTapped(_ sender: AnyObject) {
        presentAlertConfirmation(NSLocalizedString("Current order will be discarded and a new order will be created.", comment: "Discard and new order warning message"), sender: sender as! UIButton, confirmedAction: newOrder)
    }

    @IBAction func payTapped(_ sender: AnyObject) {
        // check amount list, if no element, it dosen't make sense
        guard !amountList.isEmpty else {
            presentAlertInvalidation(NSLocalizedString("The order make no sense if no item is selected.", comment: "Error message for empty order"))
            return
        }
        
        presentAlertConfirmation(NSLocalizedString("Current order will be payed and closed, and also a new order will be created.", comment: "Pay order warning message"), sender: sender as! UIButton, confirmedAction: payOrder)
    }
    
    // MARK - tool functions
    func newOrder(_ : UIAlertAction? = nil) {
        orderDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        idLabel.text = DateFormatter.localizedString(from: orderDate!, dateStyle: .medium, timeStyle: .medium)
        nameLabel.text = defaultGuestName
        emptyCart()
    }
    
    func emptyCart(_ : UIAlertAction? = nil) {
        totalLabel.text = "\(defaultTotal)"
        amountList.removeAll()
        for cell in tableView.visibleCells {
            (cell as! OrderItemCell).amount = 0
        }
    }
    
    func payOrder(_: UIAlertAction? = nil) {
        // generate order
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let guest = nameLabel.text
        let orderObj = NSEntityDescription.insertNewObject(forEntityName: "Order", into: context)
        orderObj.setValue(orderDate, forKey: "id")
        orderObj.setValue(guest, forKey: "guest")
        let orderItemList: NSSet = []
        for (indexPath, amount) in amountList {
            let orderItemObj = NSEntityDescription.insertNewObject(forEntityName: "OrderItem", into: context)
            orderItemObj.setValue(amount, forKey: "amount")
            if let menuItemObj = fetchController?.object(at: indexPath) {
                orderItemObj.setValue(menuItemObj, forKey: "menu_item")
            } else {
                fatalError("Failed to located menu_item object")
            }
            orderItemList.adding(orderItemObj)
        }
        if orderItemList.count > 0 {
            orderObj.setValue(orderItemList, forKey: "items")
        }
        
        // pay for order with cash only
        presentCashPayment(total: Double(totalLabel.text!)!)
        
        // create new order
        newOrder()
    }

    func presentAlertInvalidation(_ errorMessage: String) {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Title for Error Message Box"), message: errorMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: "Title of OK button"), style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    func presentAlertConfirmation(_ questionMessage: String, sender: UIButton, confirmedAction: ((UIAlertAction)->Void)?) {
        let alert = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Title for Confirm Message Box"), message: questionMessage, preferredStyle: .actionSheet)
        let actionYes = UIAlertAction(title: NSLocalizedString("Yes", comment: "Title of Yes button"), style: .destructive, handler: confirmedAction)
        let actionNo = UIAlertAction(title: NSLocalizedString("No", comment: "Title of No button"), style: .cancel, handler: nil)
        alert.addAction(actionYes)
        alert.addAction(actionNo)
        
        if let ppc = alert.popoverPresentationController {
            ppc.sourceView = sender
            ppc.sourceRect = sender.frame
        }
        present(alert, animated: true, completion: nil)
    }
    
    // MARK - unimplement completely
    func presentCashPayment(total: Double) {
        let cashPaymentController = CashPaymentController(nibName: "CashPaymentController", bundle: nil)
        cashPaymentController.payment = total
        cashPaymentController.modalPresentationStyle = .popover
        present(cashPaymentController, animated: true, completion: nil)
        if let presentationController = cashPaymentController.popoverPresentationController {
            presentationController.permittedArrowDirections = [.left, .right]
            presentationController.sourceView = payButton
            presentationController.sourceRect = payButton.frame
        }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let context = fetchController?.managedObjectContext {
            navigationItem.rightBarButtonItem?.isEnabled = context.hasChanges
        }
    }
    
    func saveTapped() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.saveContext()
        }
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Order item cell delegate
    func totalChanged(sender: OrderItemCell) {
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

    // MARK: - Feched results controller delegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        navigationItem.rightBarButtonItem?.isEnabled = true
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
            navigationItem.rightBarButtonItem?.isEnabled = true
        case .update:
            // Using dequeueResuableCell will cause that table view counldn't refresh data
            if let cell = tableView.cellForRow(at: indexPath!) as? OrderItemCell {
                if let amount = amountList[indexPath!] {
                    cell.amount = amount
                } else {
                    cell.amount = 0
                }
                configure(for: cell, objMenuItem: anObject)
            }
            navigationItem.rightBarButtonItem?.isEnabled = true
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order Item Cell", for: indexPath) as! OrderItemCell
        
        // Configure the cell with amount from amount list
        if let amount = amountList[indexPath] {
            cell.amount = amount
        } else {
            cell.amount = 0
        }

        // Configure the cell with info from fetched result controller
        configure(for: cell, objMenuItem: fetchController?.object(at: indexPath))
        
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
    
    // tool func for configure table view cell with managed object
    func configure(for cell: OrderItemCell, objMenuItem: Any) {
        cell.delegate = self
        if let obj = objMenuItem as? NSManagedObject, let name = obj.value(forKey: "name") as? String, let price = obj.value(forKey: "price") as? Double {
            let icon = obj.value(forKey: "icon") as? Data
            cell.configure(name: name, image: icon, price: price)
        } else {
            fatalError("Failed to display item info")
        }
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
                // fetched results controller delegate will received notification to perform table view update
                // storage could not be updated till context is saved
            }
            //            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let itemInfoViewController = segue.destination as? ItemInfoViewController, let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell), let obj = fetchController?.object(at: indexPath) {
            itemInfoViewController.objectMenuItem = obj as? NSManagedObject
            itemInfoViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Unsell", comment: "Unsell Button Title"), style: .done, target: itemInfoViewController, action: #selector(ItemInfoViewController.unsell))
        }
    }

}

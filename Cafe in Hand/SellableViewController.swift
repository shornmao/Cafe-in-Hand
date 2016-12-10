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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!
    
    internal var amountDict : [String:Int] = [:]
    internal var fetchController : NSFetchedResultsController<NSFetchRequestResult>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        totalLabel.text = "0.00"

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
    func amountChanged(sender: OrderItemCell, deltaAmount: Int) {
        let value = Int(sender.amountStepper.value)
        if let name = sender.nameLabel.text {
            if value != 0 {
                amountDict[name] = value
            } else {
                amountDict.removeValue(forKey: name)
            }
        } else {
            fatalError("Invalid item name")
        }
        if let price = Double(sender.priceLabel.text!), deltaAmount != 0, let totalString = totalLabel.text, let total = Double(totalString) {
            totalLabel.text = "\(total + Double(deltaAmount) * price)"
        }
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
            var amountVal = 0
            if let val = amountDict[name] {
                amountVal = val
            }
            cell.configure(name: name, price: price, image: icon, amount: amountVal)
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

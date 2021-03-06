//
//  UnsellableTableViewController.swift
//  Cafe in Hand
//
//  Created by Shorn Mo on 2016/11/30.
//  Copyright © 2016年 Shorn Mo. All rights reserved.
//

import UIKit
import CoreData

class UnsellableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var fetchController : NSFetchedResultsController<NSFetchRequestResult>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(UnsellableViewController.saveTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // use fetched results controller
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MenuItem")
        request.predicate = NSPredicate(format: "%K == NO", "on_stock")
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
    
    // MARK: - Fetched result delegate
    
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // calculate sections count from fetched result controller
        return (fetchController?.sections?.count)!
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // calculate rows count of one section from fetched result controller
        guard fetchController?.sections?.isEmpty == false else {
            return 0
        }
        if let sectionInfo = fetchController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Menu Item Cell", for: indexPath)

        // Configure the cell with info from fetched result controller
        if let obj = fetchController?.object(at: indexPath) as? NSManagedObject {
            let name = obj.value(forKey: "name") as? String
            let price = obj.value(forKey: "price") as? Double
            let currency = NSLocale.current.currencyCode
            cell.textLabel?.text = name!
            cell.detailTextLabel?.text = "\(price!) \(currency!)"
            if let icon = obj.value(forKey: "icon") as? Data {
                cell.imageView?.image = UIImage(data: icon)
            } else {
                cell.imageView?.image = nil
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard fetchController?.sections?.isEmpty == false else {
            return nil
        }
        if let sectionInfo = fetchController?.sections?[section] {
            return sectionInfo.name
        }
        return nil
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // get object from fetched results controller
            if let obj = fetchController?.object(at: indexPath) as? NSManagedObject {
                // delete object from context
                fetchController?.managedObjectContext.delete(obj)
                // fetched results controller delegate will received notification to perform table view update
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
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
        if let itemInfoViewController = segue.destination as? ItemInfoViewController, let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell), let obj = fetchController?.object(at: indexPath) {
            itemInfoViewController.objectMenuItem = obj as? NSManagedObject
            itemInfoViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Sell", comment: "Sell Button Title"), style: .done, target: itemInfoViewController, action: #selector(ItemInfoViewController.sell))
        }
    }

}
